function [rewRate, trial_start_rew_rate, trial_start_dff, rew_disp_dff, rew_disp_rew_rate] = rewardRate_noITI(dataSt)




    tauList = 100 : 25 : 500;
    pad = 300000;
    sampleRate = 100; % sampling rate
    mouseIDs = fieldnames(dataSt);
    
    allRewardRates = [];
    allSwitchTimes = [];
    rewardSwitchCorrelation = NaN(size(dataSt, 2), 14);
    a = 1; c = 1;
    mouseCode = []; 
    for iMouse = 1 : length(mouseIDs)
                
        behaviorData = dataSt(1).(char(mouseIDs(iMouse)));
        nTrials = size(behaviorData, 2);
        trialDurations = [behaviorData.programmedDuration] / 10;                                                                                % Convert to 
        
        longTrials = cellfun(@(x) ~isempty(x), {behaviorData.SwitchDepart}) & cellfun(@(x) x == 18000, {behaviorData.programmedDuration});
        longTrials(1) = 0;                                                                                                               % Don't include the first trial.
        switchTimes = [behaviorData(longTrials).SwitchDepart];

        % correctLongTrials = cellfun(@(x) ~isempty(x), {behaviorData.reward}) & cellfun(@(x) x == 18000, {behaviorData.programmedDuration});
        % correctLongTrials(1) = 0;                                                                                                               % Don't include the first trial.
        % switchTimes = [behaviorData(correctLongTrials).SwitchDepart];
        allSwitchTimes = [allSwitchTimes; switchTimes'];
        
        b = 1;
        for jTau = tauList
            
            kernel = exp((-linspace(0, 5 * jTau, sampleRate * jTau) / jTau));
    
            % Calculate the reward rate using a leaky integrator.
            x = 0;
            rewardRate = zeros(2, sum(trialDurations) + pad);
            for kTrial = 1 : nTrials
                index = x + round((behaviorData(kTrial).reward) * 100);     
                if isempty(index)                                                           % If no reward, just go through trial and add 2s buffer.       
                    if kTrial ~= 1 
                        rewardRate(2,x) = 1;
                    end
                    x = x + trialDurations(kTrial) + 200;        
                else
                    rewardRate(1, index : index + length(kernel) - 1) = rewardRate(1, index : index + length(kernel) - 1) + kernel;      
                    if kTrial ~= 1
                        rewardRate(2, x) = 1;
                    end
                    rewardRate(2, index) = 2;
                    x = index + 200;
                end
            end
            
            % pull out reward rates at trial start and switch times
            trialStarts = [1 find(rewardRate(2,:) == 1)];
            trialStartRewardRate = rewardRate(1, trialStarts);  
            correctTrialStartRewardRate = trialStartRewardRate(longTrials)';
    
            rewardSwitchCorrelation(a, b) = corr(correctTrialStartRewardRate, switchTimes');
            
            allRewardRates(c : c + length(correctTrialStartRewardRate) - 1, b) = correctTrialStartRewardRate;  
            
    %         all_weights = [all_weights; ones(sum(switch_trials),1)*dataSt(i_mouse).weight];
            
    %         sex_code = [sex_code; ones(sum(switch_trials),1)*sex(i_mouse)];
    %         
            b = b + 1;
        end

        mouseCode = [mouseCode; ones(length(switchTimes),1) * iMouse];

        a = a + 1;
        c = c + length(correctTrialStartRewardRate);
    end
    %     [val, idx] = min(st_corr);
    %     min_st_corr(i_mouse,1) = val;
    %     min_st_corr(i_mouse,2) = idx+49;
    %     
    %     [val, idx] = max(st_corr);
    %     max_st_corr(i_mouse,1) = val;
    %     max_st_corr(i_mouse,2) = idx+49;  
    %end
    
    for iTau = 1 : size(allRewardRates, 2)
        [switchTimeCorrelation(1, iTau), switchTimeCorrelation(2, iTau)] = corr(allRewardRates(:, iTau), allSwitchTimes);
    end

    figure(4);
    for iTau = 1 : 16
        rewardRatesToPlot = allRewardRates(:, iTau);
        switchToPlot = allSwitchTimes;
        switchToPlot(rewardRatesToPlot == 0) = [];
        rewardRatesToPlot(rewardRatesToPlot == 0) = [];
        subplot(4, 4, iTau)
        cla; hold on
        scatter(rewardRatesToPlot, switchToPlot);
        lsline;
        [rho, p] = corr(rewardRatesToPlot, switchToPlot);
        text(0.55, 3, sprintf('r = %d', rho));
        text(0.55, 1, sprintf('p = %d', p));
        xlabel('Reward Rate');
        ylabel('Switch Time (s)')
        title(sprintf('Tau = %d', tauList(iTau)))
    end
     
    
    % figure(1); clf; cla; hold on;
    % for iTau = 1 : size(rewardSwitchCorrelation, 2)
    %     scatter(ones(size(rewardSwitchCorrelation, 1), 1) * iTau, rewardSwitchCorrelation(:, iTau), 70, 'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'w');
    %     line([0.2+iTau 0.5+iTau], [mean(rewardSwitchCorrelation(:, iTau),'omitnan') mean(rewardSwitchCorrelation(:, iTau),'omitnan')], 'LineWidth', 3, 'Color', 'r');
    % end
    % 
    
    TABLE = table(allSwitchTimes, allRewardRates(:, 12), mouseCode, 'VariableNames', {'switchTime', 'rewardRate', 'Mouse'});
    writetable(TABLE, '/Users/asbova/Documents/MATLAB/switch_rewardRate/results/rewardRateSaline.csv')

    



