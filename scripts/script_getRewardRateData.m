
addpath('/Volumes/BovaData1/MATLAB/RewardRate')
cd('/Volumes/BovaData1/AnalyzedData/reward_rate')
session_dates = readtable('HannahMadisonMouseIDs.csv');
session_dates.Date1.Format = 'MM/dd/yy';
session_dates.Date2.Format = 'MM/dd/yy';

MSN = {'Switch_18L6R_SITI_RI_MAW' 'Switch_6L18R_SITI_RI_MAW' 'Switch_6L18R_SITI_REINFORCE' 'Switch_18L6R_SITI_REINFORCE'...
    'PavCond_Alex' 'Switch_18L6R_SITI_REINFORCE_FP_V3' 'Switch_6L18R_SITI_REINFORCE_FP_V3'};

mouse_ids = unique(session_dates.MouseID);
mpcParsed = getDataIntr('/Users/asbova/Resilio Sync/Beh_Left', MSN, mouse_ids);
mpcParsed2 = getDataIntr('/Users/asbova/Resilio Sync/Beh_Right', MSN, mouse_ids);

allMPC = [mpcParsed, mpcParsed2];

dataSt = [];
for i_mouse = 1 : size(session_dates,1)
    
    dataSt(i_mouse).mouse_id = char(session_dates.MouseID(i_mouse));
    dataSt(i_mouse).sex = char(session_dates.Sex(i_mouse));
    
    dataSt(i_mouse).session1_date = char(session_dates.Date1(i_mouse));       
    match_idx = find(strcmp(dataSt(i_mouse).mouse_id, {allMPC.Subject}) & strcmp(dataSt(i_mouse).session1_date, {allMPC.StartDate}));
    if numel(match_idx) == 1
        dataSt(i_mouse).mpc1 = allMPC(match_idx);
        dataSt(i_mouse).beh1 = getTrialData_Switch(dataSt(i_mouse).mpc1);
    end
    
    dataSt(i_mouse).session2_date = char(session_dates.Date2(i_mouse));
    match_idx = find(strcmp(dataSt(i_mouse).mouse_id, {allMPC.Subject}) & strcmp(dataSt(i_mouse).session2_date, {allMPC.StartDate}));
    if numel(match_idx) == 1
        dataSt(i_mouse).mpc2 = allMPC(match_idx);
        dataSt(i_mouse).beh2 = getTrialData_Switch(dataSt(i_mouse).mpc2);
    end
end

save('hannah_data.mat', 'dataSt')
