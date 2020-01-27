function EEG = RS_resyncERP(EEG,cfg)

%handling error
for hand_e = 1:1
if ~isfield(cfg,'elec_indx') && ~isfield(cfg,'selected_elec')
    ME = MException('a:b','No electrode(s) selected');
    throw(ME)
end
if ~isfield(cfg,'marker_indx') && ~isfield(cfg,'selected_marker')
    ME = MException('a:b','No marker(s) selected');
    throw(ME)
end
end

if ~isfield(cfg,'selected_marker')
cfg.selected_marker = cfg.marker_label(cfg.marker_indx);
end
if ~isfield(cfg,'selected_elec')
cfg.selected_elec = cfg.elec_label(cfg.elec_indx);
end
ch = find(ismember(lower({EEG.chanlocs.labels}),lower(cfg.selected_elec)));

data = mean(EEG.data(ch,:),1);
cfg.srate = EEG.srate;
cfg.latencies = round([EEG.event(ismember({EEG.event.type},cfg.selected_marker)).latency]);

if ~isfield(EEG,'ReSync') EEG.ReSync = {};end
if cfg.glb == 1 cfg.fig_visible = 'off';end
results = ReSync(data, cfg);
data = results.resync_data;
if cfg.glb == 1
EEG.data = ReSync_w_lat(EEG.data,cfg,results.est_latency);
EEG.ReSync{end+1} = results;
end




