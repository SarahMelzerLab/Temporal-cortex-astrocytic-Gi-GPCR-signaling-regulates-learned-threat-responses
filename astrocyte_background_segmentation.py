"""Robust background-normalized thresholds for calibrated 3D fluorescence.

Thresholds are estimated independently of treatment labels.  Per-Z background
location and noise are measured from deterministic spatial samples outside a
soma-centered exclusion cylinder, then smoothed only along Z.  The result is a
fixed formula that can be calibrated and frozen before group comparisons.
"""

def robust_background_by_z(processed, soma_zyx, spacing_zyx_um, config, ndi, np):
    """Estimate a robust background median and noise scale for every Z plane."""
    cfg = config.get("background", config)
    stride = max(1, int(cfg.get("xy_sample_stride", 8)))
    exclusion_um = float(cfg.get("soma_xy_exclusion_radius_um", 30.0))
    upper_percentile = float(cfg.get("sample_upper_percentile", 99.5))
    sigma_floor = float(cfg.get("sigma_floor_intensity", 0.5))
    smooth_um = float(cfg.get("z_smoothing_um", 1.0))

    sampled_y = np.arange(0, processed.shape[1], stride)
    sampled_x = np.arange(0, processed.shape[2], stride)
    dy_um = (sampled_y[:, None] - float(soma_zyx[1])) * float(spacing_zyx_um[1])
    dx_um = (sampled_x[None, :] - float(soma_zyx[2])) * float(spacing_zyx_um[2])
    outside_soma = dy_um**2 + dx_um**2 >= exclusion_um**2
    if not np.any(outside_soma):
        outside_soma = np.ones((len(sampled_y), len(sampled_x)), bool)

    medians, sigmas, sample_counts, upper_cuts = [], [], [], []
    for z in range(processed.shape[0]):
        values = np.asarray(processed[z, ::stride, ::stride][outside_soma], float)
        values = values[np.isfinite(values)]
        if len(values) == 0:
            raise ValueError(f"No valid background samples in Z plane {z}.")
        upper = float(np.percentile(values, upper_percentile))
        core = values[values <= upper]
        median = float(np.median(core))
        mad = float(np.median(np.abs(core - median)))
        robust_sigma = max(sigma_floor, 1.4826 * mad)
        medians.append(median)
        sigmas.append(robust_sigma)
        sample_counts.append(int(len(core)))
        upper_cuts.append(upper)

    z_window = max(1, int(round(smooth_um / float(spacing_zyx_um[0]))))
    if z_window % 2 == 0:
        z_window += 1
    median_z = ndi.median_filter(np.asarray(medians, float), size=z_window, mode="nearest")
    sigma_z = ndi.median_filter(np.asarray(sigmas, float), size=z_window, mode="nearest")
    return median_z, sigma_z, {
        "xy_sample_stride": stride,
        "soma_xy_exclusion_radius_um": exclusion_um,
        "sample_upper_percentile": upper_percentile,
        "sigma_floor_intensity": sigma_floor,
        "z_smoothing_um": smooth_um,
        "z_smoothing_window_planes": z_window,
        "median_by_z": median_z,
        "robust_sigma_by_z": sigma_z,
        "sample_count_by_z": sample_counts,
        "upper_sample_cut_by_z": upper_cuts,
    }
