

clear;

%--------run on EEG dataset----------
%load the sample data first
%the data 'vp26_clean.set' can be downloaded from 
%https://github.com/guangouyang/ReSync

EEG = pop_loadset('filename','vp26_clean.set','filepath',...
    'C:\Dropbox\work\code\eeglab_current\eeglab2019_0\plugins\ReSync1.0\sample_data\');


cfg = [];
cfg.epoch_twd = [-200,1000];%in millisecond
cfg.base_twd = [-200,0];
cfg.resync_twd = [200,400];
cfg.selected_elec = {'Oz'};
cfg.selected_marker = {'S 11','S 12','S 13'};
cfg.glb = 1;

EEG = RS_resyncERP(EEG,cfg);


cfg.resync_twd = [400,800];
EEG = RS_resyncERP(EEG,cfg);

figure;plot(EEG.ReSync{1}.t,EEG.ReSync{1}.original_ERP,'k');
hold on;plot(EEG.ReSync{2}.t,EEG.ReSync{2}.resync_ERP,'r');
xlabel('time (ms)');ylabel('ERP (\muV)');
legend({'Before ReSync','After ReSync'});







%---------directly run on a time series-----
%data and parameter preparation (remember to reload EEG data!!!)
elec = {'Oz'};
data = mean(EEG.data(ismember({EEG.chanlocs.labels},elec),:),1);
marker = {'S 11','S 12','S 13'};
latencies = round([EEG.event(ismember({EEG.event.type},marker)).latency]);
srate = EEG.srate;
 
%applying ReSync on a time series
cfg = [];
cfg.srate = srate;
cfg.latencies = latencies;
cfg.epoch_twd = [-200,1000];
cfg.base_twd = [-200,0];
cfg.resync_twd = [200,400];
results = ReSync(data, cfg);
