
parallel -j 20 bash /home/admin/Desktop/MRIapp/scripts/WMH/WMH_MNI_withQC.sh --robust \
/home/admin/Desktop/MRI/MNI/MNI152_T1_1mm_brain.nii.gz \
/home/admin/Desktop/MRI/MNI/ventricles_bin.nii.gz \
/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal_3TP \
{} ::: sub-HD001 sub-HD007 sub-HD018 sub-HD030 sub-HD035 sub-HD036 sub-HD041 sub-HD049 sub-HD050 sub-HD051 sub-HD053 sub-HD057 sub-HD058 sub-HD059 sub-HD060 sub-HD062 sub-HD066 sub-HD067 sub-HD068 sub-HD069 sub-HD075 sub-HD076 sub-HD077 sub-HD078 sub-HD080 sub-HD084 sub-HD086 sub-HD092 sub-HD094 sub-HD095 sub-HD098 sub-HD102 sub-HD103 sub-HD115 sub-HD116 sub-HD119 sub-HD126 sub-HD130 sub-HD134 sub-HD142 sub-HD143 sub-HD144 sub-HD147 sub-HD149 sub-HD150 sub-HD155 sub-HD156 sub-HD158 sub-HD159 sub-HD165 sub-HD166 sub-HD170 sub-HD172 sub-HD173 sub-HD174 sub-HD175 sub-HD176 sub-HD179 sub-HD180 sub-HD181 sub-HD182 sub-HD187 sub-HD188 sub-HD191 sub-HD193 sub-HD195 sub-HD197 sub-HD200 sub-HD202 sub-HD205 sub-HD208 sub-HD211 sub-HD213 sub-HD215 sub-HD217 sub-HD219 sub-HD220 sub-HD222 sub-HD223 sub-HD225 sub-HD229 sub-HD230 sub-HD232 sub-HD236 sub-HD237 sub-HD241 sub-HD243 sub-HD248 sub-HD249 sub-HD251 sub-HD252 sub-HD254 sub-HD255 sub-HD257 sub-HD258 sub-HD259 sub-HD261 sub-HD266 sub-HD267 sub-HD268 sub-HD269 sub-HD273 sub-HD274 sub-HD276 sub-HD280 sub-HD281 sub-HD283 sub-HD284 sub-HD285 sub-HD286 sub-HD287 sub-HD288 sub-HD296 sub-HD297 sub-HD299 sub-HD306 sub-HD310 sub-HD313 sub-HD315 sub-HD317 sub-HD318 sub-HD321 sub-HD322 sub-HD326 sub-HD327 sub-HD329 sub-HD330 sub-HD331 sub-HD333 sub-HD334 sub-HD335 sub-HD336 sub-HD337 sub-HD339 sub-HD340 sub-HD342 sub-HD343 sub-HD344 sub-HD347 sub-HD348 sub-HD349 sub-HD350 sub-HD354 sub-HD357 sub-HD360 sub-HD363 sub-HD364 sub-HD365 sub-HD366 sub-HD367 sub-HD368 sub-HD369 sub-HD370 sub-HD371 sub-HD372 sub-HD373 sub-HD374 sub-HD375 sub-HD377 sub-HD378 sub-HD379 sub-HD380 sub-HD381 sub-HD383 sub-HD384 sub-HD385 sub-HD386 sub-HD387 sub-HD388 sub-HD389 sub-HD390 sub-HD393 sub-HD394 sub-HD395 sub-HD396 sub-HD397 sub-HD399 sub-HD407 sub-HD409 sub-HD413 sub-HD417 sub-HD420 sub-HD422 sub-HD426 sub-HD427 sub-HD428 sub-HD431 sub-HD432 sub-HD433 sub-HD436 sub-HD437 sub-HD438 sub-HD446 sub-HD448 sub-HD453 sub-HD461 sub-HD462 sub-HD463 sub-HD464 sub-HD466 sub-HD470 sub-HD473 sub-HD474 sub-HD475 sub-HD479 sub-HD481 sub-HD482 sub-HD484 sub-HD486 sub-HD487 sub-HD489 sub-HD490 sub-HD492 sub-HD493 sub-HD494 sub-HD495 sub-HD496 sub-HD498 sub-HD503 sub-HD504 sub-HD506 sub-HD508 sub-HD510 sub-HD516 sub-HD517 sub-HD518 sub-HD519 sub-HD520 sub-HD521 sub-HD525 sub-HD527 sub-HD533 sub-HD535 sub-HD537 sub-HD538 sub-HD542 sub-HD543 sub-HD544 sub-HD550 sub-HD552 sub-HD553 sub-HD562 sub-HD564 sub-HD565 sub-HD567 sub-HD571 sub-HD572 sub-HD581 sub-HD590 sub-HD591 sub-HD598 sub-HD600 sub-HD601 sub-HD602 sub-HD603 sub-HD604 sub-HD606 sub-HD607 sub-HD608 sub-HD620 sub-HD639

bash /home/admin/Desktop/MRIapp/scripts/WMH/step1_WMH_MNI.sh \
/home/admin/Desktop/MRI/MNI/MNI152_T1_1mm_brain.nii.gz \
/home/admin/Desktop/MRI/MNI/ventricles_bin.nii.gz \
/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal_3TP sub-HD094 sub-HD165 sub-HD600 sub-HD603


bash /home/admin/Desktop/MRIapp/scripts/WMH/WMH_MNI_withQC.sh --robust \
/home/admin/Desktop/MRI/MNI/MNI152_T1_1mm_brain.nii.gz \
/home/admin/Desktop/MRI/MNI/ventricles_bin.nii.gz \
/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal_3TP sub-HD116





#DWPV distance-based 10 to 13 mm
parallel -j 15 bash /home/admin/Desktop/MRIapp/scripts/WMH/step3_WMH_PVDW_10to13mm.sh \
/home/admin/Desktop/MRI/MNI/ventricles_bin.nii.gz \
/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal_3TP \
{} ::: sub-HD094 sub-HD165 sub-HD600 sub-HD603


#DWPV Original
parallel -j 15 bash /home/admin/Desktop/MRIapp/scripts/WMH/merged/WMH_PVDW.sh \
/home/admin/Desktop/MRI/MNI/ventricles_bin.nii.gz \
/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal_3TP \
{} ::: sub-HD001 sub-HD007 sub-HD018 sub-HD030 sub-HD035 sub-HD036 sub-HD041 sub-HD049 sub-HD050 sub-HD051 sub-HD053 sub-HD057 sub-HD058 sub-HD059 sub-HD060 sub-HD062 sub-HD066 sub-HD067 sub-HD068 sub-HD069 sub-HD075 sub-HD076 sub-HD077 sub-HD078 sub-HD080 sub-HD084 sub-HD086 sub-HD092 sub-HD094 sub-HD095 sub-HD098 sub-HD102 sub-HD103 sub-HD115 sub-HD116 sub-HD119 sub-HD126 sub-HD130 sub-HD134 sub-HD142 sub-HD143 sub-HD144 sub-HD147 sub-HD149 sub-HD150 sub-HD155 sub-HD156 sub-HD158 sub-HD159 sub-HD165 sub-HD166 sub-HD170 sub-HD172 sub-HD173 sub-HD174 sub-HD175 sub-HD176 sub-HD179 sub-HD180 sub-HD181 sub-HD182 sub-HD187 sub-HD188 sub-HD191 sub-HD193 sub-HD195 sub-HD197 sub-HD200 sub-HD202 sub-HD205 sub-HD208 sub-HD211 sub-HD213 sub-HD215 sub-HD217 sub-HD219 sub-HD220 sub-HD222 sub-HD223 sub-HD225 sub-HD229 sub-HD230 sub-HD232 sub-HD236 sub-HD237 sub-HD241 sub-HD243 sub-HD248 sub-HD249 sub-HD251 sub-HD252 sub-HD254 sub-HD255 sub-HD257 sub-HD258 sub-HD259 sub-HD261 sub-HD266 sub-HD267 sub-HD268 sub-HD269 sub-HD273 sub-HD274 sub-HD276 sub-HD280 sub-HD281 sub-HD283 sub-HD284 sub-HD285 sub-HD286 sub-HD287 sub-HD288 sub-HD296 sub-HD297 sub-HD299 sub-HD306 sub-HD310 sub-HD313 sub-HD315 sub-HD317 sub-HD318 sub-HD321 sub-HD322 sub-HD326 sub-HD327 sub-HD329 sub-HD330 sub-HD331 sub-HD333 sub-HD334 sub-HD335 sub-HD336 sub-HD337 sub-HD339 sub-HD340 sub-HD342 sub-HD343 sub-HD344 sub-HD347 sub-HD348 sub-HD349 sub-HD350 sub-HD354 sub-HD357 sub-HD360 sub-HD363 sub-HD364 sub-HD365 sub-HD366 sub-HD367 sub-HD368 sub-HD369 sub-HD370 sub-HD371 sub-HD372 sub-HD373 sub-HD374 sub-HD375 sub-HD377 sub-HD378 sub-HD379 sub-HD380 sub-HD381 sub-HD383 sub-HD384 sub-HD385 sub-HD386 sub-HD387 sub-HD388 sub-HD389 sub-HD390 sub-HD393 sub-HD394 sub-HD395 sub-HD396 sub-HD397 sub-HD399 sub-HD407 sub-HD409 sub-HD413 sub-HD417 sub-HD420 sub-HD422 sub-HD426 sub-HD427 sub-HD428 sub-HD431 sub-HD432 sub-HD433 sub-HD436 sub-HD437 sub-HD438 sub-HD446 sub-HD448 sub-HD453 sub-HD461 sub-HD462 sub-HD463 sub-HD464 sub-HD466 sub-HD470 sub-HD473 sub-HD474 sub-HD475 sub-HD479 sub-HD481 sub-HD482 sub-HD484 sub-HD486 sub-HD487 sub-HD489 sub-HD490 sub-HD492 sub-HD493 sub-HD494 sub-HD495 sub-HD496 sub-HD498 sub-HD503 sub-HD504 sub-HD506 sub-HD508 sub-HD510 sub-HD516 sub-HD517 sub-HD518 sub-HD519 sub-HD520 sub-HD521 sub-HD525 sub-HD527 sub-HD533 sub-HD535 sub-HD537 sub-HD538 sub-HD542 sub-HD543 sub-HD544 sub-HD550 sub-HD552 sub-HD553 sub-HD562 sub-HD564 sub-HD565 sub-HD567 sub-HD571 sub-HD572 sub-HD581 sub-HD590 sub-HD591 sub-HD598 sub-HD600 sub-HD601 sub-HD602 sub-HD603 sub-HD604 sub-HD606 sub-HD607 sub-HD608 sub-HD620 sub-HD639

parallel -j 15 bash /home/admin/Desktop/MRIapp/scripts/WMH/merged/WMH_PVDW_10to13mm.sh \
/home/admin/Desktop/MRI/MNI/ventricles_bin.nii.gz \
/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal_3TP \
{} ::: sub-HD094 sub-HD165 sub-HD600 sub-HD603

bash /home/admin/Desktop/MRIapp/scripts/WMH/merged/extract_WMHvol_copy.sh \
/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal_3TP \
/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal_3TP/WMH_vol.csv sub-HD030

TODO (2)
# Brain Lobes
bash /home/admin/Desktop/MRIapp/scripts/WMH/step4_WMH_lobes.sh \
/home/admin/Desktop/MRI/MNI/brainlobes_MNI152_1mm.nii.gz \
/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal_3TP sub-HD094 sub-HD165 sub-HD600 sub-HD603

# Volume
bash /home/admin/Desktop/MRIapp/scripts/WMH/merged/extract_WMHvol_copy.sh \
/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal_3TP \
/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal_3TP/WMH_vol.csv sub-HD094 sub-HD165 sub-HD600 sub-HD603

bash /home/admin/Desktop/MRIapp/scripts/WMH/merged/extract_WMHtotalvolonly.sh \
/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal_3TP \
/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal_3TP/WMH_vol.csv sub-HD094 sub-HD165 sub-HD600 sub-HD603

bash /home/admin/Desktop/MRIapp/scripts/WMH/merged/extract_WMHvol_ALLROI.sh \
/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal_3TP \
/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal_3TP/WMH_vol_4.csv sub-HD094 sub-HD165 sub-HD600 sub-HD603


sub-HD001 sub-HD007 sub-HD018 sub-HD030 sub-HD035 sub-HD036 sub-HD041 sub-HD049 sub-HD050 sub-HD051 sub-HD053 sub-HD057 sub-HD058 sub-HD059 sub-HD060 sub-HD062 sub-HD066 sub-HD067 sub-HD068 sub-HD069 sub-HD075 sub-HD076 sub-HD077 sub-HD078 sub-HD080 sub-HD084 sub-HD086 sub-HD092 sub-HD094 sub-HD095 sub-HD098 sub-HD102 sub-HD103 sub-HD115 sub-HD116 sub-HD119 sub-HD126 sub-HD130 sub-HD134 sub-HD142 sub-HD143 sub-HD144 sub-HD147 sub-HD149 sub-HD150 sub-HD155 sub-HD156 sub-HD158 sub-HD159 sub-HD165 sub-HD166 sub-HD170 sub-HD172 sub-HD173 sub-HD174 sub-HD175 sub-HD176 sub-HD179 sub-HD180 sub-HD181 sub-HD182 sub-HD187 sub-HD188 sub-HD191 sub-HD193 sub-HD195 sub-HD197 sub-HD200 sub-HD202 sub-HD205 sub-HD208 sub-HD211 sub-HD213 sub-HD215 sub-HD217 sub-HD219 sub-HD220 sub-HD222 sub-HD223 sub-HD225 sub-HD229 sub-HD230 sub-HD232 sub-HD236 sub-HD237 sub-HD241 sub-HD243 sub-HD248 sub-HD249 sub-HD251 sub-HD252 sub-HD254 sub-HD255 sub-HD257 sub-HD258 sub-HD259 sub-HD261 sub-HD266 sub-HD267 sub-HD268 sub-HD269 sub-HD273 sub-HD274 sub-HD276 sub-HD280 sub-HD281 sub-HD283 sub-HD284 sub-HD285 sub-HD286 sub-HD287 sub-HD288 sub-HD296 sub-HD297 sub-HD299 sub-HD306 sub-HD310 sub-HD313 sub-HD315 sub-HD317 sub-HD318 sub-HD321 sub-HD322 sub-HD326 sub-HD327 sub-HD329 sub-HD330 sub-HD331 sub-HD333 sub-HD334 sub-HD335 sub-HD336 sub-HD337 sub-HD339 sub-HD340 sub-HD342 sub-HD343 sub-HD344 sub-HD347 sub-HD348 sub-HD349 sub-HD350 sub-HD354 sub-HD357 sub-HD360 sub-HD363 sub-HD364 sub-HD365 sub-HD366 sub-HD367 sub-HD368 sub-HD369 sub-HD370 sub-HD371 sub-HD372 sub-HD373 sub-HD374 sub-HD375 sub-HD377 sub-HD378 sub-HD379 sub-HD380 sub-HD381 sub-HD383 sub-HD384 sub-HD385 sub-HD386 sub-HD387 sub-HD388 sub-HD389 sub-HD390 sub-HD393 sub-HD394 sub-HD395 sub-HD396 sub-HD397 sub-HD399 sub-HD407 sub-HD409 sub-HD413 sub-HD417 sub-HD420 sub-HD422 sub-HD426 sub-HD427 sub-HD428 sub-HD431 sub-HD432 sub-HD433 sub-HD436 sub-HD437 sub-HD438 sub-HD446 sub-HD448 sub-HD453 sub-HD461 sub-HD462 sub-HD463 sub-HD464 sub-HD466 sub-HD470 sub-HD473 sub-HD474 sub-HD475 sub-HD479 sub-HD481 sub-HD482 sub-HD484 sub-HD486 sub-HD487 sub-HD489 sub-HD490 sub-HD492 sub-HD493 sub-HD494 sub-HD495 sub-HD496 sub-HD498 sub-HD503 sub-HD504 sub-HD506 sub-HD508 sub-HD510 sub-HD516 sub-HD517 sub-HD518 sub-HD519 sub-HD520 sub-HD521 sub-HD525 sub-HD527 sub-HD533 sub-HD535 sub-HD537 sub-HD538 sub-HD542 sub-HD543 sub-HD544 sub-HD550 sub-HD552 sub-HD553 sub-HD562 sub-HD564 sub-HD565 sub-HD567 sub-HD571 sub-HD572 sub-HD581 sub-HD590 sub-HD591 sub-HD598 sub-HD600 sub-HD601 sub-HD602 sub-HD603 sub-HD604 sub-HD606 sub-HD607 sub-HD608 sub-HD620 sub-HD639

#Rerun QC
bash /home/admin/Desktop/MRIapp/scripts/WMH/run_DWPV_QC.sh \
/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal_3TP \
"[-5 0 5 10 15]" sub-HD094 sub-HD165 sub-HD600 sub-HD603

# MERGE

bash /home/admin/Desktop/MRIapp/scripts/WMH/merged_WMH.sh \
/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal_3TP \
"BL Y2" \
WMH_common_inMNI.nii.gz \
WMH_common_inMNI_binfinal.nii.gz \
sub-HD094 sub-HD165 sub-HD600 sub-HD603


bash /home/admin/Desktop/MRIapp/scripts/WMH/merged/merged_WMH.sh \
/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal_3TP \
"BL Y2 Y4Y5" \
WMH_common_inMNI.nii.gz \
WMH_common_inMNI_binfinal.nii.gz \
sub-HD378 sub-HD379 sub-HD383 sub-HD388 sub-HD389 sub-HD394 sub-HD407 sub-HD409 sub-HD436 sub-HD438 sub-HD481 sub-HD493 sub-HD494 sub-HD495 sub-HD498 sub-HD521 sub-HD527 sub-HD533 sub-HD543 sub-HD544 sub-HD550 sub-HD565 sub-HD581 sub-HD604


TODO
bash /home/admin/Desktop/MRIapp/scripts/WMH/step1_WMH_MNI.sh \
/home/admin/Desktop/MRI/MNI/MNI152_T1_1mm_brain.nii.gz \
/home/admin/Desktop/MRI/MNI/ventricles_bin.nii.gz \
/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal_3TP sub-HD094

parallel -j 15 bash /home/admin/Desktop/MRIapp/scripts/WMH/merged/WMH_PVDW.sh \
/home/admin/Desktop/MRI/MNI/brainlobes_MNI152_1mm.nii.gz \
/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal_3TP \
{} ::: sub-HD094

parallel -j 15 bash /home/admin/Desktop/MRIapp/scripts/WMH/merged/WMH_PVDW_10to13mm.sh \
/home/admin/Desktop/MRI/MNI/ventricles_bin.nii.gz \
/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal_3TP \
{} ::: sub-HD094

parallel -j 15 bash /home/admin/Desktop/MRIapp/scripts/WMH/merged/WMH_lobes.sh \
/home/admin/Desktop/MRI/MNI/brainlobes_MNI152_1mm.nii.gz \
/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal_3TP \
{} ::: sub-HD094

bash /home/admin/Desktop/MRIapp/scripts/WMH/merged/extract_WMHvol_ALLROI.sh \
/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal_3TP \
/mnt/hdd/MT/HARMY/HARMY_WMH/derivatives/Longitudinal_3TP/WMH_vol_3.csv sub-HD094