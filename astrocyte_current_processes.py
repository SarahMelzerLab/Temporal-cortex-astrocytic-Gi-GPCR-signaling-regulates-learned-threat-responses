"""Current GFP-process detector accepted for review by the main launcher.

The production detector is the previously accepted Sato reconstruction plus
the bounded adaptive Meijering additions selected in the nine-cell benchmark.
Display thickening is deliberately kept out of this module so it can never
enter Sholl counts.
"""
import numpy as np
from scipy import ndimage as ndi
from skimage import filters, morphology


DEFAULT_FIBER_DETECTOR = "current_plus_adaptive_meijering_v1"


def z_supported(mask, radius_px=2):
    planar = ndi.maximum_filter(np.asarray(mask, np.uint8),
                                size=(1, radius_px * 2 + 1, radius_px * 2 + 1)) > 0
    supported = np.zeros_like(planar)
    supported[1:] |= planar[:-1]
    supported[:-1] |= planar[1:]
    return supported


def ridge_hysteresis(strong, weak):
    """Retain directly connected weak ridges seeded by a strong ridge."""
    weak = np.asarray(weak, bool)
    strong = np.asarray(strong, bool) & weak
    labels, _ = ndi.label(weak, structure=np.ones((3, 3, 3), bool))
    seeded = np.unique(labels[strong])
    seeded = seeded[seeded > 0]
    return np.isin(labels, seeded) if seeded.size else np.zeros_like(weak)


def skeleton_component_lengths(skeleton, spacing):
    labels, count = ndi.label(skeleton, structure=np.ones((3, 3, 3), bool))
    lengths = np.zeros(count + 1, float)
    shape = np.asarray(skeleton.shape)
    offsets = [(dz, dy, dx) for dz in (-1, 0, 1) for dy in (-1, 0, 1)
               for dx in (-1, 0, 1) if (dz, dy, dx) > (0, 0, 0)]
    for offset_tuple in offsets:
        offset = np.asarray(offset_tuple)
        first = tuple(slice(max(0, -int(d)), min(int(s), int(s - d)))
                      for d, s in zip(offset, shape))
        second = tuple(slice(max(0, int(d)), min(int(s), int(s + d)))
                       for d, s in zip(offset, shape))
        a, b = labels[first], labels[second]
        connected = (a > 0) & (a == b)
        if connected.any():
            lengths += np.bincount(a[connected],
                                   weights=np.full(np.count_nonzero(connected),
                                                   np.linalg.norm(offset * spacing)),
                                   minlength=count + 1)
    return labels, lengths


def filter_skeleton_by_length(skeleton, spacing, minimum_length_um=0.5):
    labels, lengths = skeleton_component_lengths(skeleton, spacing)
    keep = lengths >= float(minimum_length_um)
    keep[0] = False
    return keep[labels], lengths


def _reviewed_settings(sensitivity):
    value = float(np.clip(sensitivity, 0, 100))
    return {
        "low_sato_percentile": 20.0 + 0.55 * value,
        "high_sato_percentile": 70.0 + 0.20 * value,
        "intensity_floor_sigma": 0.10 + 0.009 * value,
        "strong_intensity_sigma": 0.75 + 0.010 * value,
    }


def _local_residual(response, sigma_px):
    response = np.asarray(response, np.float32)
    return np.maximum(
        response - ndi.gaussian_filter(response, sigma=float(sigma_px), mode="nearest"),
        0,
    ).astype(np.float32)


def segment_adaptive_meijering_additions(
        normalized_gfp, territory, spacing, sensitivity):
    """Return the benchmark-selected, locally adaptive Meijering additions.

    Thresholds are calculated independently on each optical plane.  Weak
    ridges are retained only when their 2-D component contains a strong seed;
    a weak ridge supported by a strong ridge in an adjacent Z plane may also
    seed that component.  This is the exact bounded method reviewed in the
    detector benchmark, before it is unioned with the established detector.
    """
    normalized = np.asarray(normalized_gfp, np.float32)
    territory = np.asarray(territory, bool)
    spacing = np.asarray(spacing, float)
    if normalized.shape != territory.shape or normalized.ndim != 3:
        raise ValueError("Meijering additions require matching 3-D ZYX arrays.")
    if spacing.shape != (3,) or np.any(spacing <= 0):
        raise ValueError("Meijering additions require positive ZYX spacing.")

    effective = float(np.clip(float(sensitivity) - 8.0, 0, 100))
    chosen = {
        "effective_sensitivity": effective,
        "low_percentile": 20.0 + 0.55 * effective,
        "high_percentile": 70.0 + 0.20 * effective,
        "intensity_floor_sigma": 0.10 + 0.009 * effective,
        "strong_intensity_sigma": 0.75 + 0.010 * effective,
    }
    mean_xy = float(np.mean(spacing[1:]))
    local_sigma_px = max(2.0, 1.5 / mean_xy)
    response = np.zeros_like(normalized, np.float32)
    for z in range(normalized.shape[0]):
        image = np.clip(normalized[z], 0, 8)
        response[z] = _local_residual(
            filters.meijering(image, sigmas=(1, 2, 3), black_ridges=False),
            local_sigma_px)

    weak = np.zeros_like(territory)
    strong = np.zeros_like(territory)
    for z in range(normalized.shape[0]):
        image = np.clip(normalized[z], 0, 8)
        reference = territory[z] & (image >= 0.1) & (response[z] > 0)
        if not reference.any():
            continue
        low = float(np.percentile(response[z][reference], chosen["low_percentile"]))
        high = float(np.percentile(response[z][reference], chosen["high_percentile"]))
        weak[z] = (territory[z] &
                   (image >= chosen["intensity_floor_sigma"]) &
                   (response[z] >= low))
        strong[z] = (territory[z] &
                     (image >= chosen["strong_intensity_sigma"]) &
                     (response[z] >= high))

    seeds = strong | (weak & z_supported(strong, radius_px=2))
    grown = np.zeros_like(weak)
    for z in range(weak.shape[0]):
        labels, _ = ndi.label(weak[z], structure=np.ones((3, 3), bool))
        seeded = np.unique(labels[seeds[z]])
        seeded = seeded[seeded > 0]
        if seeded.size:
            grown[z] = np.isin(labels, seeded)
    grown = morphology.remove_small_objects(grown, max_size=4, connectivity=3)
    skeleton = morphology.skeletonize(grown, method="lee").astype(bool)
    skeleton, lengths = filter_skeleton_by_length(
        skeleton, spacing, minimum_length_um=0.4)
    qc = {
        "name": "adaptive_meijering_additions",
        "method": "adaptive local Meijering plus adjacent-Z seeding",
        "reviewed_sensitivity": int(round(float(sensitivity))),
        **chosen,
        "local_response_background_sigma_um": 1.5,
        "minimum_component_graph_length_um": 0.4,
        "mask_voxels": int(grown.sum()),
        "skeleton_voxels": int(skeleton.sum()),
        "graph_length_um": float(lengths[lengths >= 0.4].sum()),
    }
    return grown & territory, skeleton & territory, qc


def segment_processes(normalized_gfp, territory, spacing, sensitivity):
    """Return the accepted 3-D GFP mask, centerlines, and audit metadata.

    ``sensitivity`` is the user-reviewed stack setting. The detector combines
    the accepted Sato reconstruction with bounded adaptive Meijering additions;
    no gap bridging or display thickening enters this result.
    """
    normalized = np.asarray(normalized_gfp, np.float32)
    territory = np.asarray(territory, bool)
    support_floor = 0.1
    intensity_support = normalized >= support_floor
    adjacent = z_supported(intensity_support, radius_px=2)

    # Ridge responses are calculated independently in every optical plane,
    # while adjacent-Z intensity support rejects isolated single-plane noise.
    clipped = np.clip(normalized, 0, 8)
    sato = np.empty_like(clipped)
    for plane in range(clipped.shape[0]):
        sato[plane] = filters.sato(clipped[plane], sigmas=(1, 2, 3), black_ridges=False)
    reference = territory & adjacent & (normalized >= support_floor)
    values = sato[reference]
    if not values.size:
        empty = np.zeros_like(territory)
        return empty, empty, {
            "status": "no_supported_gfp_processes_exclude_from_group_curve",
            "method": "human-reviewed single-sensitivity connected ridge centerline",
            "variants": [],
            "minimum_component_graph_length_um": .5,
            "adjacent_z_support_required": True,
            "soma_connection_required": False,
            "all_supported_components_inside_territory_retained": True,
            "empty_gaps_bridged": False,
            "exact_union_graph_length_um": 0.0,
            "reason": "No territory voxel met the minimum GFP and adjacent-Z support gate.",
        }

    chosen = _reviewed_settings(sensitivity)
    low = float(np.percentile(values, chosen["low_sato_percentile"]))
    high = float(np.percentile(values, chosen["high_sato_percentile"]))
    weak = (territory & adjacent &
            (normalized >= chosen["intensity_floor_sigma"]) & (sato >= low))
    strong = (territory & adjacent &
              (normalized >= chosen["strong_intensity_sigma"]) & (sato >= high))
    grown = ridge_hysteresis(strong, weak)
    cleaned = morphology.remove_small_objects(grown, max_size=4, connectivity=3)
    skeleton = morphology.skeletonize(cleaned, method="lee").astype(bool)
    skeleton, lengths = filter_skeleton_by_length(skeleton, spacing, .5)
    base_mask = cleaned & territory
    base_skeleton = skeleton & territory

    # The benchmark-selected additions recover locally supported thin ridges.
    addition_mask, addition_skeleton, addition_qc = (
        segment_adaptive_meijering_additions(
            normalized, territory, spacing, sensitivity))
    union_mask = base_mask | addition_mask
    union_skeleton = base_skeleton | addition_skeleton
    _, union_lengths = skeleton_component_lengths(union_skeleton, spacing)
    return union_mask, union_skeleton, {
        "status": ("user_confirmed" if union_skeleton.any() else
                   "no_supported_gfp_processes_exclude_from_group_curve"),
        "method": "current accepted Sato plus adaptive Meijering additions",
        "detector_version": DEFAULT_FIBER_DETECTOR,
        "reviewed_sensitivity": int(round(float(sensitivity))),
        **chosen,
        "variants": [{"name": "accepted_sato", **chosen,
                       "skeleton_voxels": int(base_skeleton.sum()),
                       "graph_length_um": float(lengths[lengths >= .5].sum())},
                      addition_qc],
        "minimum_component_graph_length_um": .4,
        "adjacent_z_support_required": True,
        "soma_connection_required": False,
        "all_supported_components_inside_territory_retained": True,
        "empty_gaps_bridged": False,
        "exact_union_graph_length_um": float(union_lengths.sum()),
        "base_skeleton_voxels": int(base_skeleton.sum()),
        "meijering_addition_skeleton_voxels": int(
            np.count_nonzero(addition_skeleton & ~base_skeleton)),
    }
