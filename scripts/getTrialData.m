%% Code built to pull switch data from MedPC files
%% Adjusted from Youngcho's getTrialData and Ben's getTrialData_Bisection
    % getTrialData_Bisection.m, Benjamin De Corte 2017. Organize mpc output for bisection task.
%% Austin Bruce, Tomas Lence, and Matt Weber

%% Changes to make - notes go here

%% Not sure what this is for - remnant of Ben's 
%change choice configuration list to 12 and 21 for left solid / right blink and left blink / right solid
%Add G as a variable and SET G(C(^trialCounter)) = 1 for left choices and SET G(C(^trialCounter)) = 2; for right pokes make sure everything is sealed
% S8, \ correction trial
%     0.01": 
%         IF (C(^goodTrial) >= 1)  [@LOGDATA;@IGNOREDATA] \ logging correct/incorrect/correction like this will make it easier to integrate with matlab (i.e., goodtrialsindex=L>0)
% 	   @LOGDATA:    SET L(C(^trialCounter)) = 2; ---> SX; \ log that this non-correction trial was correct
% 	   @IGNOREDATA: SET L(C(^trialCounter)) = 0; ---> SX; !!!\ log that this was a correction trial. 
% 
%         ADD C(^trialCounter); 
%         SET C(^CorrectionTrial) = 1 ---> S9 

%% following are data format from MEDPC output file
%{
From Bisection task

\   A       Probe trial selection array
\   B       Reward counter
\   D
\   E       Interval Record Array
\   F
\   G       center nosepoke in array
\   H       Trial Start time record array
\   I       Variable Interval arrary
\   K       List of random ITI range
\   L       Log good trial accuracy data
\   M       Correction Trial tracker

\   N	    RIGHT NP response time record array
\   O       RIGHT NP release time record array

\   P       LEFT NP Response Time (Beam Break) record array
\   Q       LEFT NP Response Time (Beam Release) record array
\   R	    Opto laser on (1) or off (2)
\   S       Trial End time record array
\   T       Probe trial record array
\   U       ITI record array
\   V	    Probe length
\   W       Pellet dispense time record array
\   X       milli second Timer for recoring events
\   Y       Reward zone out record array
\   Z       Reward zone in record array
\-----------------------------------------
\----------------------------------------------------------
%}

%% Starts to pull values from MedPC files
function TrialAnSt = getTrialData(mpcParsed)

uniqueSbj = unique({mpcParsed.Subject});
nmpcType = min(cellfun(@length, {mpcParsed.H}), cellfun(@length, {mpcParsed.S}))> 0; % check if any trials

for i_animal = 1:size(uniqueSbj,2)
    sbjIdx = strcmp(uniqueSbj(i_animal),{mpcParsed.Subject}) &  nmpcType;
    sbjLineIdx = find(sbjIdx);
    numOfDays = sum(sbjIdx);
    animals = char(uniqueSbj(i_animal));  

    for i_day = 1:numOfDays
        lineIdx =sbjLineIdx(i_day);
        if contains(mpcParsed(lineIdx).MSN,'18L6R')
            type = 1;
        elseif contains(mpcParsed(lineIdx).MSN,'6L18R')
            type = 0;
        else
            type = NaN;
        end
            
        timeITI = mpcParsed(lineIdx).U';
        trialStart = mpcParsed(lineIdx).H'; % 1
        trialEnd = mpcParsed(lineIdx).S'; % 2
        trialStart=trialStart(1:length(trialEnd));
        trialType = mpcParsed(lineIdx).T'; % the programmed duration for the trial
        trialType=trialType(1:length(trialEnd));
        reward = mpcParsed(lineIdx).W';
        opto = mpcParsed(lineIdx).R'; opto = opto==1; % 1 means laser is off. 2 is on
            
        rpInLeft = mpcParsed(lineIdx).P'; % responding on left NP
        rpOutLeft = mpcParsed(lineIdx).Q';
        rpInRight = mpcParsed(lineIdx).N'; % responding on right NP
        rpOutRight = mpcParsed(lineIdx).O';
        rpInBack = mpcParsed(lineIdx).F'; % responding on right NP
%         rpOutBack = mpcParsed(lineIdx).G'; % correct: being used for NP out and side choice...
%         fzIn = mpcParsed(lineIdx).Z';
%         fzOut = mpcParsed(lineIdx).Y';

        trialOutcomeInfo = mpcParsed(lineIdx).L'; % 4 = correct trial, 3 = incorrect trial, 2 = correct correction trial, 1 = incorrect correction trial
        if type == 0    % 0 indicates that a short latency trial is rewarded at the left nose poke
            rsp_in_short = rpInLeft;
            rsp_out_short = rpOutLeft;
        elseif type == 1
            rsp_in_short = rpInRight;
            rsp_out_short =rpOutRight;          
        end
        
        if numel(rsp_in_short) == numel(rsp_out_short)
            rsp_short_duration = rsp_out_short - rsp_in_short;
        elseif numel(rsp_in_short) == numel(rsp_out_short)+1 && rsp_in_short(end) > rsp_out_short(end)
            rsp_short_duration = rsp_out_short - rsp_in_short(1:end-1);
        end
            
        trial = struct;
        trialNum = min(length(trialStart), length(trialEnd));
        for j = 1:trialNum
            %% trial start/end time, duration, and ITI
            curTS = trialStart(j); % H 
            curTE = trialEnd(j);
            trial(j).trialStart = curTS;
            trial(j).trialEnd = curTE;
            trial(j).trialDuration = curTE - curTS;
            trial(j).ITI = timeITI(j);
            
            %% real trial start time (when mouse iniated)
            x = rpInBack-curTS;
            trial(j).initiationRT = min(x(x>=0)); % timestamp of first response after the trial was initiated
            curTS =  trial(j).initiationRT +  curTS; % add the reaction time to trial start (when back light turned on), get the real trial start. 
            trial(j).realTrialStart = curTS;
            
            %% programmed duration for the trial
            trial(j).programmedDuration = trialType(j);
            
            %% opto
             if numel(opto)~=0; trial(j).opto = opto(j); end
             
            %% outcome info
            trial(j).outcome = trialOutcomeInfo(j);
            
            %% response time within trial
            trial(j).leftRspTimeTrial = rpInLeft(rpInLeft>curTS & rpInLeft<=curTE) - curTS;
            trial(j).leftRelTimeTrial = rpOutLeft(rpOutLeft>curTS & rpOutLeft<=curTE) - curTS;
            trial(j).rightRspTimeTrial = rpInRight(rpInRight>curTS & rpInRight<=curTE) - curTS;
            trial(j).rightRelTimeTrial = rpOutRight(rpOutRight>curTS & rpOutRight<=curTE) - curTS;
            
            if type == 0    % 0 indicates that a short latency trial is rewarded at the left nose poke
                short_rel = trial(j).leftRelTimeTrial;
                long_rsp = trial(j).rightRspTimeTrial;
            elseif type == 1
                short_rel = trial(j).rightRelTimeTrial;
                long_rsp = trial(j).leftRspTimeTrial;                
            else
                error('')
            end
            switch_arrival = [];
            switch_depart = [];            
            if ~isempty(short_rel) && ~isempty(long_rsp) && any(long_rsp > min(short_rel)) && trialType(j) == 18000
                switch_arrival = min(long_rsp(long_rsp > min(short_rel)));
                switch_depart = max(short_rel(short_rel < switch_arrival));
            end
            % Include the portion below if you want to include short trial switches
%             if ~isempty(short_rel) && ~isempty(long_rsp) && any(long_rsp > min(short_rel)) && trialType(j) == 6000
%                 switch_arrival = min(long_rsp(long_rsp > min(short_rel)));
%                 switch_depart = max(short_rel(short_rel < switch_arrival));
%             end
            trial(j).SwitchArrival = switch_arrival;
            trial(j).SwitchDepart = switch_depart;
            trial(j).ShortRsp = short_rel;
            trial(j).LongRsp = long_rsp;            
  
            %% time from ITI end to trial initiation poke
            x = rpInBack - trialStart(j);
            trial(j).initiationRT = min(x(x>=0)); % timestamp of first response after the trial was initiated
            
            %% reaction time: time from signal offset to first response
            startPoke = min(rpInBack(rpInBack >= trialStart(j))); % timestamp of first back poke after trial start
            durationElapsed = startPoke+(trialType(j)./1000); % time that the duration elapsed
            potentialRTs = [min(rpInLeft(rpInLeft>=durationElapsed)) min(rpInRight(rpInRight>=durationElapsed))]; % finds first responses after duration elapsed on left and right nosepokes
            trial(j).RT = min(potentialRTs) - durationElapsed; 

            %% reward entries/exits relative to trial end
%             trial(j).rewardEntryTimes = fzIn - curTE;
%             trial(j).rewardExitTimes = fzIn - curTE;
            trial(j).reward = reward(reward>curTS & reward<=curTE+0.2) - curTS;
        end
        %trial(1).rsp_short_duration = rsp_short_duration;
        trial(1).mpc = mpcParsed(lineIdx); % just saves everything
        TrialAnSt(i_day).(animals) = trial; %
        %trial(1).ratio = length([TrialAnSt(i_animal).(animals).reward])/length([TrialAnSt(i_animal).(animals)])
        %TrialAnSt(i_day).(animals)([TrialAnSt(i_day).(animals).trialStart] < 2.7e+03) = [];
    end

end

end