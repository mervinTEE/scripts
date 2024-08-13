# topup
source ~/.bashrc
fslroi dMRI_dir124_PA.nii.gz b0_PA 0 1
fslroi dMRI_b0_AP.nii.gz B0_AP 0 1
fslmerge -t AP_PA_B0 B0_AP.nii.gz B0_PA.nii.gz

# Create acqparams.txt
# May need to do dos2unix acqparams.txt
topup --imain=AP_PA_B0.nii.gz --datain=acqparams.txt --config=b02b0_1.cnf --out=topup_AP_PA_scan
fsleyes topup_AP_PA_scan_fieldcoef.nii.gz



#applytopup is not necessary, this is to generate nii for preview
applytopup --imain=B0_AP.nii.gz,B0_PA.nii.gz --inindex=1,2 --datain=acqparams.txt --topup=topup_AP_PA_scan --out=hifi_b0_AP_PA.nii.gz

# eddy
fslmaths hifi_b0_AP_PA.nii.gz -Tmean hifi_b0_AP_PA.nii.gz
bet hifi_b0_AP_PA.nii.gz hifi_b0_AP_PA_brain -m -f 0.2

#Creating Index file based on total number of volumes determined from bval file
myVar=$(wc -w < dMRI_dir124_PA.bval)
indx=""
for ((i=1; i<=myVar; i+=1)); do
    indx+="1"$'\n'  # Add a newline character after each "1"
done
printf "%s" "$indx" > index.txt


#For Checking Bvals
cat dMRI_dir124_PA.bval | xargs -n 1 | sort -n | uniq -c

#creating acqparams that matches dwi volumes
fslroi dMRI_dir124_PA.nii.gz dMRI_dir124_PA_124.nii.gz 0 -1 0 -1 0 -1 0 124 #extracting last volume that cannot be used

dim4=$(fslinfo dMRI_dir124_PA_124.nii.gz | awk '/dim4/{printf "%.0f", $2}'); for ((i=1; i<=dim4; i++)); do printf "0 1 0 0.0732\n" >> acqparams.txt; done



eddy --imain=dMRI_dir124_PA_124.nii.gz --mask=hifi_b0_AP_PA_brain_mask.nii.gz --acqp=acqparams.txt --index=index.txt --bvecs=dMRI_dir124_PA.bvec --bvals=dMRI_dir124_PA.bval --fwhm=10,0,0,0,0 --topup=topup_AP_PA_scan --flm=quadratic --out=eddy_unwarped_images --verbose --data_is_shelled
