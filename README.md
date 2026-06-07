System requirements:
- Codes were written with Windows 10 and 11 and MATLAB R2022a
- No other versions were tested
- No non-standard software is required

Installation guide:
- No specific installation needed. MATLAB used for all codes.
- NA

Demo/Instructions:
- For primary codes: the codes directly analyze and synchronize video recordings (30fps) and photometry/Arduino outputs (2052 Hz). A GUI interface allows to select start and end of video.  
- For all 'followup' codes: Source data needs to be compiled in analysis folders as indicated in the code. Each group/condition will need to be sorted into one folder.
- RNAseqAnalysis_Melzerlab.m requires downloading the GEO files before using the code.
- Expected output: final results figures as png and affinity files as well as matlab files containing key variables and statistics.
- Expected runtime: minutes (photometry, RNAseq) to hours (behavior, imaging)


License
-------

This project is licensed under the GNU General Public License v3.0 (GPL-3.0). See the LICENSE file for details.
