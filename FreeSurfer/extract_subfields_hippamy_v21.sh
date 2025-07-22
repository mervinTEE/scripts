#!/bin/bash

echo 'SubjID,L_Hippocampal_tail,L_subiculum-body,L_CA1-body,L_subiculum-head,L_hippocampal-fissure,L_presubiculum-head,L_CA1-head,L_presubiculum-body,L_parasubiculum,L_molecular_layer_HP-head,L_molecular_layer_HP-body,L_GC-ML-DG-head,L_CA3-body,L_GC-ML-DG-body,L_CA4-head,L_CA4-body,L_fimbria,L_CA3-head, L_HATA,L_Whole_hippocampal_body,L_Whole_hippocampal_head,L_Whole_hippocampus,R_Hippocampal_tail,R_subiculum-body,R_CA1-body,R_subiculum-head,R_hippocampal-fissure,R_presubiculum-head,R_CA1-head,R_presubiculum-body,R_parasubiculum,R_molecular_layer_HP-head,R_molecular_layer_HP-body,R_GC-ML-DG-head,R_CA3-body,R_GC-ML-DG-body,R_CA4-head,R_CA4-body,R_fimbria,R_CA3-head,R_HATA,R_Whole_hippocampal_body,R_Whole_hippocampal_head,R_Whole_hippocampus,Lhippo,Rhippo,eTIV,Brain,TotalGM,L_Lateral-nucleus,L_Basal-nucleus,L_Accessory-Basal-nucleus,L_Anterior-amygdaloid-area-AAA,L_Central-nucleus,L_Medial-nucleus,L_Cortical-nucleus,L_Corticoamygdaloid-transitio,L_Paralaminar-nucleus,L_Whole_amygdala, R_Lateral-nucleus,R_Basal-nucleus,R_Accessory-Basal-nucleus,R_Anterior-amygdaloid-area-AAA,R_Central-nucleus,R_Medial-nucleus,R_Cortical-nucleus,R_Corticoamygdaloid-transitio,R_Paralaminar-nucleus,R_Whole_amygdala,Lamy,Ramy' > hippoamy_subfields.csv

#for subj_id in $(ls -d WG_*); do # approach A: create the list here, e. g. for rootname 'WG_' in this example
for subj_id in $(cat /mnt/hdd/MT/NEURO_BMC/NEURO-HIPPO/list.txt); do # approach B: use an explicit list

printf "%s,"  "${subj_id}" >> hippoamy_subfields.csv


# SUBFIELDS

for x in Measure:volume Hippocampal_tail subiculum-body CA1-body subiculum-head hippocampal-fissure presubiculum-head CA1-head presubiculum-body parasubiculum molecular_layer_HP-head molecular_layer_HP-body GC-ML-DG-head CA3-body GC-ML-DG-body CA4-head CA4-body fimbria CA3-head HATA Whole_hippocampal_body Whole_hippocampal_head Whole_hippocampus; do
printf "%g," `grep -w ${x} ${subj_id}/freesurfer/stats/hipposubfields_combined.txt | awk '{print $2}'` >> hippoamy_subfields.csv
done

done
for x in Hippocampal_tail subiculum-body CA1-body subiculum-head hippocampal-fissure presubiculum-head CA1-head presubiculum-body parasubiculum molecular_layer_HP-head molecular_layer_HP-body GC-ML-DG-head CA3-body GC-ML-DG-body CA4-head CA4-body fimbria CA3-head HATA Whole_hippocampal_body Whole_hippocampal_head Whole_hippocampus; do
printf "%g," `grep -w ${x} ${subj_id}/mri/rh.hippoSfVolumes-T1.v22.txt | awk '{print $2}'` >> hippoamy_subfields.csv
done

for x in Left-Hippocampus Right-Hippocampus; do
printf "%g," `grep  ${x} ${subj_id}/stats/aseg.stats | awk '{print $4}'` >> hippoamy_subfields.csv
done

# GLOBALS

printf "%g," `cat ${subj_id}/stats/aseg.stats | grep IntraCranialVol | awk -F, '{print $4}'` >> hippoamy_subfields.csv
printf "%g," `cat ${subj_id}/stats/aseg.stats | grep 'Brain Segmentation Volume,' | awk -F, '{print $4}'` >> hippoamy_subfields.csv
printf "%g," `cat ${subj_id}/stats/aseg.stats | grep  'Total gray matter volume' | awk -F, '{print $4}'` >> hippoamy_subfields.csv


# AMYGDALA

for x in Lateral-nucleus Basal-nucleus Accessory-Basal-nucleus Anterior-amygdaloid-area-AAA Central-nucleus Medial-nucleus Cortical-nucleus Corticoamygdaloid-transitio Paralaminar-nucleus Whole_amygdala; do
printf "%g," `grep -w ^${x} ${subj_id}/mri/lh.amygNucVolumes-T1.v22.txt | awk '{print $2}'` >> hippoamy_subfields.csv
done

for x in Lateral-nucleus Basal-nucleus Accessory-Basal-nucleus Anterior-amygdaloid-area-AAA Central-nucleus Medial-nucleus Cortical-nucleus Corticoamygdaloid-transitio Paralaminar-nucleus Whole_amygdala; do
printf "%g," `grep -w ^${x} ${subj_id}/mri/rh.amygNucVolumes-T1.v22.txt | awk '{print $2}'` >> hippoamy_subfields.csv
done

for x in Left-Amygdala; do
printf "%g," `grep  ${x} ${subj_id}/stats/aseg.stats | awk '{print $4}'` >> hippoamy_subfields.csv
done

for x in Right-Amygdala; do
printf "%g" `grep  ${x} ${subj_id}/stats/aseg.stats | awk '{print $4}'` >> hippoamy_subfields.csv
done

echo "" >> hippoamy_subfields.csv

done
