function [rewRate, trial_start_rew_rate, trial_start_dff, rew_disp_dff, rew_disp_rew_rate] = rewardRateITI(dataSt)





    pad = 3000000;
    sampleRate = 100; % sampling rate
    mouseIDs = fieldnames(dataSt);
    
    allRewardRates = [];
    allSwitchTimes = [];
    rewardSwitchCorrelation = NaN(size(dataSt, 2), 14);
    a = 1; c = 1;
    for iMouse = 1 : length(mouseIDs)
                       
        behaviorData = dataSt(1).(char(mouseIDs(iMouse)));
        trialStartTimes = [behaviorData.realTrialStart];
        rewardTimes = behaviorData(1).mpc.W;
        trialDurations = [behaviorData.programmedDuration] / 10;   

        correctLongTrials = cellfun(@(x) ~isempty(x), {behaviorData.reward}) & cellfun(@(x) x == 18000, {behaviorData.programmedDuration});
        correctLongTrials(1) = 0;                                                                                                               % Don't include the first trial.
        switchTimes = [behaviorData(correctLongTrials).SwitchDepart];
        allSwitchTimes = [allSwitchTimes; switchTimes'];
        % 
        b = 1;
        for jTau = 100 : 25 : 500
            
            kernel = exp((-linspace(0, 5 * jTau, sampleRate * jTau) / jTau));

            % Calculate the reward rate using a leaky integrator.
            rewardRate = zeros(2, sum(trialDurations) + pad);
            for kTrial = 1 : length(rewardTimes)
                rewardIndex = round(rewardTimes(kTrial) * 100);
                rewardRate(1, rewardIndex : rewardIndex + length(kernel) - 1) = rewardRate(1, rewardIndex : rewardIndex + length(kernel) - 1) + kernel;  
                rewardRate(2, rewardIndex) = 2;
            end
            for kTrial = 1 : length(trialStartTimes)
                rewardRate(2, round(trialStartTimes(kTrial) * 100)) = 1;
            end

            % Pull out reward rates at trial start and switch times
            trialStarts = rewardRate(2,:) == 1;
            trialStartRewardRate = rewardRate(1, trialStarts);  
            correctTrialStartRewardRate = trialStartRewardRate(correctLongTrials)';
    
            rewardSwitchCorrelation(a, b) = corr(correctTrialStartRewardRate, switchTimes');            
            allRewardRates(c : c + length(correctTrialStartRewardRate) - 1, b) = correctTrialStartRewardRate;  
      
            b = b + 1;
        end

        a = a + 1;
        c = c + length(correctTrialStartRewardRate);
    end

    for iTau = 1 : size(allRewardRates, 2)
        [switchTimeCorrelation(1, iTau), switchTimeCorrelation(2, iTau)] = corr(allRewardRates(:, iTau), allSwitchTimes);
    end

    figure(2);
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
    end
     
    % 
    % figure(1); clf; cla; hold on;
    % for iTau = 1 : size(rewardSwitchCorrelation, 2)
    %     scatter(ones(size(rewardSwitchCorrelation, 1), 1) * iTau, rewardSwitchCorrelation(:, iTau), 70, 'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'w');
    %     line([0.2+iTau 0.5+iTau], [mean(rewardSwitchCorrelation(:, iTau),'omitnan') mean(rewardSwitchCorrelation(:, iTau),'omitnan')], 'LineWidth', 3, 'Color', 'r');
    % end
    
    
    % TBL = table(all_st, all_rew_rates, all_weights, mouse_code, sex_code, 'VariableNames', {'switch_time', 'rew_rate', 'weight', 'mouse', 'sex'});
    % writetable(TBL, '/Volumes/BovaData1/AnalyzedData/optrode/rewrate.csv')
    % 
    % [r, p] = corr(all_st, all_rew_rates)
    % 
    % %figure;
    % % scatter(trial_start_rew_rate, trial_start_dff); hold on;
    % % lsline;
    % 
    % scatter(rew_disp_rew_rate, rew_disp_dff); hold on;
    % lsline;
    % 
    % scatter(trial_start_rew_rate(switch_trials), switch_times(switch_trials)); hold on;
    % lsline;
    



