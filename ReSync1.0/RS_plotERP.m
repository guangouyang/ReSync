function ERP_results = RS_plotERP(EEG,cfg)

epoch_twd = cfg.epoch_twd;
base_twd = cfg.base_twd;

%handling error
for hand_e = 1:1
if ~isfield(cfg,'elec_indx')
    ME = MException('a:b','No electrode(s) selected');
    throw(ME)
end
if ~isfield(cfg,'marker_indx')
    ME = MException('a:b','No marker(s) selected');
    throw(ME)
end
if base_twd(1)< epoch_twd(1) || base_twd(2) > epoch_twd(2)
    ME = MException('baseline:exceed', ...
        'baseline window should not exceed epoch time window');
    throw(ME)
end
if epoch_twd(1) > -100
    ME = MException('epoch:window', ...
        'left end of epoch time window should be <= 100 ms ');
    throw(ME)
end
end

latencies_list = cfg.marker_label(cfg.marker_indx);
elec = cfg.elec_label(cfg.elec_indx);
ch = find(ismember(lower({EEG.chanlocs.labels}),lower(elec)));

data = mean(EEG.data(ch,:),1);
srate = EEG.srate;
latencies = round([EEG.event(ismember({EEG.event.type},latencies_list)).latency]);

sample_twd = fix(epoch_twd(1)*srate/1000):fix(epoch_twd(2)*srate/1000);

regressor = zeros(length(sample_twd),length(data));
for j = 1:length(sample_twd)
    temp = latencies + sample_twd(j);
    temp(temp<1|temp>length(data)) = [];
    regressor(j,temp) = 1;
end
ERP = regressor*data'/length(latencies);

%baseline
sample_base_twd = (round((base_twd(1)-epoch_twd(1))*srate/1000)+1):(round((base_twd(2)-epoch_twd(1))*srate/1000)+1);

ERP = ERP - mean(ERP(sample_base_twd));
t_axis = linspace(epoch_twd(1),epoch_twd(2),size(ERP,1));

single_trial = [];
%get single trials
for j = 1:length(latencies)
    sample2take = latencies(j) + sample_twd;
    sample2take(sample2take<1) = 1;
    sample2take(sample2take>length(data)) = length(data);
    single_trial(:,j) = data(sample2take);
    single_trial(:,j) = single_trial(:,j) - ...
        mean(single_trial(sample_base_twd,j));
end

figure('units','normalized','position',[.3,.05,.4,0.8]);
subplot(2,1,1);
imagesc(t_axis,1:size(single_trial,2),squeeze(single_trial(:,:))');colormap(jet);
lat_labels = join(latencies_list,' ');ele_labels = join(elec,' ');
ylabel('trials');title(['single trial and average ERP locked to ',lat_labels{1},...
    ', averaged from ',ele_labels{1}]);
subplot(2,1,2);
plot(t_axis,ERP);xlabel('time (ms)');ylabel('\muV');
axis tight;
