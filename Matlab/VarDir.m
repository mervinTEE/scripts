% Variable names
variable_names = {'age', 'space_score', 'rotationtime', 'movementtime', 'homingtime', ...
    'trainingtotaltime', 'pi_totaltime_average', 'pi_distance_average', ...
    'pi_finalangle_average', 'pointingjudgementerror_average', 'pointingjudgementtotaltime', ...
    'maptotaltime', 'maprsq', 'memorytotaltime', 'memorypercentcorrect', ...
    'perspectivetotaltime', 'perspectiveerrormeasure', 'group'};

% Define the parent directory where you want to create the directories
parentDir = '/home/admin/Desktop/MRI/MT/SPACE/SPACE_CAT12/derivatives/CAT12.8.2_2170/Results/';

for i = 1:length(variable_names)
    currentVariable = variable_names{i};
    dirName = fullfile(parentDir, currentVariable);
    mkdir(dirName);
    disp(['Directory created: ', dirName]);
end