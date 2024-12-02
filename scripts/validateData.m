function [num_long_trials, perc_correct] = validateData(dataSt)

centers = 0:0.1:20;
num_mice = size(dataSt,2);

plot_colors = {[70/255 101/255 165/255] [70/255 165/255 117/255]};

switch_times = cell(num_mice,2);
cv = NaN(num_mice,2);
cdf = cell(num_mice,2);
pdf = cell(num_mice,2);
num_long_trials = NaN(num_mice,2);
perc_correct = NaN(num_mice,2);

for i_mouse = 1 : num_mice       
    if isempty(dataSt(i_mouse).beh1) continue; end
    
    %figure(); clf;
    for i_sess = 1 : 2
        
        behname = sprintf('beh%d', i_sess);
        cur_beh = dataSt(i_mouse).(behname);
        
        long_trials = find(cellfun(@(x) x == 18000, {cur_beh.programmedDuration}));
        correct_trials = find(cellfun(@(x) ~isempty(x), {cur_beh.reward_inTrial}));
        correct_long_trials = intersect(long_trials, correct_trials);
        
        switch_times{i_mouse, i_sess} = [cur_beh(correct_long_trials).SwitchDepart];
        
        %cv
        cv(i_mouse, i_sess) = std(switch_times{i_mouse,i_sess},0,2, 'omitnan')./mean(switch_times{i_mouse,i_sess},'omitnan');
        
        % cdf & pdf
        [N,edges] = histcounts(switch_times{i_mouse,i_sess}, centers,'Normalization', 'cdf');
        [f,xi] = ksdensity(switch_times{i_mouse,i_sess}, centers(2:end), 'Bandwidth', 0.6);
        cdf{i_mouse, i_sess} = N;
        pdf{i_mouse, i_sess} = f;
        
        % percent trials correct
        num_long_trials(i_mouse,i_sess) = length(long_trials);
        perc_correct(i_mouse,i_sess) = (length(correct_long_trials)/length(long_trials))*100;
        
%         % PLOT
%         subplot(2,3,1); hold on;
%         plot(centers(2:end),cdf{i_mouse,i_sess}, 'Color', plot_colors{i_sess}, 'LineWidth', 2)
%         set(gca,'ylim',[0 1], 'xlim', [0 18], 'xtick', [0 6 18])
%         
%         subplot(2,3,[2,3]); hold on;
%         plot(centers(2:end),pdf{i_mouse,i_sess}, 'Color', plot_colors{i_sess}, 'LineWidth', 2)
%         set(gca, 'xlim', [0 18], 'xtick', [0 6 18])
%         
%         subplot(2,3,4); hold on;
%         scatter(i_sess, cv(i_mouse,i_sess), 70, 'MarkerFaceColor', plot_colors{i_sess}, 'MarkerEdgeColor', plot_colors{i_sess})
%         ylabel('CV'); set(gca, 'xlim', [0.6 2.4])
%         
%         subplot(2,3,5); hold on;
%         scatter(i_sess, num_long_trials(i_mouse,i_sess), 70, 'MarkerFaceColor', plot_colors{i_sess}, 'MarkerEdgeColor', plot_colors{i_sess})
%         ylabel('Num. Long Trials'); set(gca, 'xlim', [0.6 2.4])
%         
%         subplot(2,3,6); hold on;
%         scatter(i_sess, perc_correct(i_mouse,i_sess), 70, 'MarkerFaceColor', plot_colors{i_sess}, 'MarkerEdgeColor', plot_colors{i_sess})
%         ylabel('% Long Trials Correct'); set(gca, 'xlim', [0.6 2.4])
    end
end

% figure(1); subplot(2,2,1); cla; 
% scatter(1:num_mice, num_long_trials(:,2), 'filled');
% 
% subplot(2,2,3); cla;
% scatter(1:num_mice, perc_correct(:,2), 'filled');
% 
% select_trials = find(num_long_trials(:,2) >=30);
% subplot(2,2,2); cla;
% scatter(select_trials, num_long_trials(select_trials,2), 'filled');
% set(gca,'ylim',[0 70]);
% 
% subplot(2,2,4); cla;
% scatter(select_trials, perc_correct(select_trials,2), 'filled');
% set(gca,'ylim',[20 90]);








