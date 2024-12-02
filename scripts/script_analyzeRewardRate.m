% script_analyzeRewardRate

projectName = 'switch_rewardRate';

cd /Users/asbova/Documents/MATLAB
addpath(genpath('./switch_rewardRate'))
addpath('./switch_rewardRate/util')

medpcDataPathway = './switch_rewardRate/data/medpc';                                           % medpc files

% Get medpc behavioral data.
[protocols, group] = getMouseSessions();
if isempty(group)
    mpcParsed = getDataIntr(medpcDataPathway, protocols, mouseIDs, dateRange);
else
    mpcParsed = getDataIntr(medpcDataPathway, protocols, group);
end
trialDataStructure = getTrialData(mpcParsed);

mouseIDs = fieldnames(trialDataStructure);
nLongTrials = NaN(2, length(mouseIDs));
percentCorrect = NaN(2, length(mouseIDs));
for iMouse = 1 : length(mouseIDs)
    for jSession = 1 : 2
        sessionData = trialDataStructure(jSession).(char(mouseIDs(iMouse)));
        nLongTrials(jSession, iMouse) = sum(cellfun(@(x) x == 18000, {sessionData.programmedDuration}));
        percentCorrect(jSession, iMouse) = sum(cellfun(@(x) ~isempty(x), {sessionData.reward}) & cellfun(@(x) x == 18000, {sessionData.programmedDuration})) / nLongTrials(jSession, iMouse);
    end
end
goodSessions =  nLongTrials >= 35; %percentCorrect >= 0.55 &

for iMouse = 1 : length(mouseIDs)
    currentMouse = char(mouseIDs(iMouse));
    if goodSessions(2,iMouse) == 1
        goodTrialDataStructure.(currentMouse) = trialDataStructure(2).(currentMouse);
    end
end

rewardRate_noITI(goodTrialDataStructure)