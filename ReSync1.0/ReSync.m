% ReSync() - the function of ReSync algorithm that applies on a time series
%
% Inputs:
%   data   - a time series 1*n vector
%   cfg   - parameter configurations (see ReSync manual)
%
%
% Copyright (C) 2020  Guang Ouyang
% The University of Hong Kong
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%
% Citation: Ouyang, G. (2020). ReSync: Correcting the trial-to-trial asynchrony 
% of event-related brain potentials to improve neural response representation.





function results = ReSync(data,cfg)
disp('Start ReSyncing ...');
results.cfg = cfg;
data = data(:)';
srate = cfg.srate;
epoch_twd = cfg.epoch_twd;
base_twd = cfg.base_twd;
resync_twd = cfg.resync_twd;
% lowpass_freq = cfg.lowpass_freq;
latencies = cfg.latencies;
if ~isfield(cfg,'fig_visible') cfg.fig_visible = 'on';end
if ~isfield(cfg,'glb') cfg.glb = 0;end
%handling error
for hand_e = 1:1
if base_twd(1)< epoch_twd(1) || base_twd(2) > epoch_twd(2)
    ME = MException('baseline:exceed', ...
        'baseline window should not exceed epoch time window');
    throw(ME)
end
if resync_twd(2) - resync_twd(1) < 50
    ME = MException('template:window', ...
        'template time widnow should not be shorter than 50 ms');
    throw(ME)
end
if epoch_twd(1) > -100
    ME = MException('epoch:window', ...
        'left end of epoch time window should be <= 100 ms ');
    throw(ME)
end
end

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

sample_resync_twd = (round((resync_twd(1)-epoch_twd(1))*srate/1000)+1):(round((resync_twd(2)-epoch_twd(1))*srate/1000));

%evaluate SNR ratio
for rea = 1:100
tr_num = size(single_trial,2);n = length(sample_twd);
temp = [ones(fix(tr_num/2),1);-ones(tr_num-fix(tr_num/2),1)];
temp = temp(randperm(tr_num))';
temp1 = single_trial.*temp(ones(n,1),:);
ERP_noise = mean(temp1,2);
noise_std(rea) = std(ERP_noise(sample_resync_twd));
end
noise_std_m = mean(noise_std);



template = ERP(sample_resync_twd);

var_diff = var(template)-noise_std_m^2;var_diff(var_diff<0) = 0;
SNR = sqrt(var_diff)/(noise_std_m*sqrt(tr_num));

%determine lowpass frequency
for j = 1:length(latencies)
    sample2take = latencies(j) + sample_resync_twd + round(epoch_twd(1)*srate/1000);
    sample2take(sample2take<1) = 1;
    sample2take(sample2take>length(data)) = length(data);
    data2match = data(sample2take);
    fft_data2match(:,j) = fft(detrend(data2match),length(data2match)*10);
end
[a,b] = sort(-abs(mean(fft_data2match(1:fix(size(fft_data2match,1)/2),:),2)));


comp_period = length(sample_resync_twd)*10/(b(1)-1);
dominant_freq  = (b(1)-1)*100/(resync_twd(2)-resync_twd(1));


lowpass_freq = dominant_freq + 1;%add 1 Hz to safeguard the component activity
%x-correlation
high_cut_samp = round(lowpass_freq*10*length(template)/srate);
for j = 1:length(latencies)
    sample2take = latencies(j) + sample_resync_twd + round(epoch_twd(1)*srate/1000);
    sample2take(sample2take<1) = 1;
    sample2take(sample2take>length(data)) = length(data);
    data2match = data(sample2take);
    fft_data2match(:,j) = fft(detrend(data2match),length(data2match)*10);
    
    x_cov = xcov(data2match,template,round(length(template)/2),'coeff');
    x_cov = detrend(x_cov(:));
    x_cov = RS_filtering10(x_cov,0,high_cut_samp);
    est_latency(j) = RS_nearest_latency(x_cov,round(length(x_cov)/2));
end
est_latency = round(est_latency - median(est_latency));

%RLV: relative latency variability
RLV = std(est_latency)/comp_period;
    
figure('units','normalized','position',[0,.05,1,.85],'visible',cfg.fig_visible);
subplot(2,3,1);
imagesc(t_axis,1:length(est_latency),single_trial(:,RS_accending_index(est_latency))');colormap(jet);
xlabel('time (ms)');ylabel('trials sorted by estimated latency');
title('Original trials');


%highlight windowed activity

single_trial_hl = [];
%get single trials
for j = 1:length(latencies)
    sample2take = latencies(j) + sample_twd;
    sample2take(sample2take<1) = 1;
    sample2take(sample2take>length(data)) = length(data);
    single_trial_hl(:,j) = data(sample2take);
    single_trial_hl(:,j) = single_trial_hl(:,j) - ...
        mean(single_trial_hl(sample_base_twd,j));
    
    hl_curve = zeros(length(sample_twd),1);
    hl_curve(sample_resync_twd) = RS_tukey(length(sample_resync_twd),0.4);
    hl_curve = RS_move(hl_curve,est_latency(j),'move');
    single_trial_hl(:,j) = single_trial_hl(:,j).*hl_curve(:);
    single_trial_hl(:,j) = single_trial_hl(:,j)/std(single_trial_hl(single_trial_hl(:,j)~=0,j));
end
subplot(2,3,2);
imagesc(t_axis,1:length(est_latency),single_trial_hl(:,RS_accending_index(est_latency))');colormap(jet);
xlabel('time (ms)');ylabel('trials sorted by estimated latency');
title('highlighted activity');


regressor2 = zeros(length(sample_twd),length(data));
latencies2 = latencies + est_latency;
for j = 1:length(sample_twd)
    latencies_temp = latencies2 + sample_twd(j);
    latencies_temp(latencies_temp<1|latencies_temp>length(data)) = [];
    regressor2(j,latencies_temp) = 1;
end

ERPs = [ERP,zeros(length(ERP),1)];
if std(est_latency) ~= 0
invR = inv([regressor;regressor2]*[regressor;regressor2]')*[regressor;regressor2];
ERPs = invR*data';
ERPs = reshape(ERPs,length(ERP),2);

%re-baseline (only do it once)
for j = 1:size(ERPs,2)
    ERPs(:,j) = ERPs(:,j) - mean(ERPs(sample_base_twd,j));
end
end
    

%%%reconstructing single trial ERP

ERP_re = sum(ERPs,2);

ST = ERPs(:,1)'*regressor;
ST2 = ERPs(:,2)'*regressor2;
ST_re = ERP_re'*regressor;

data_re = data - ST - ST2 + ST_re;

single_trial_re = [];
%get single trials
for j = 1:length(latencies)
    sample2take = latencies(j) + sample_twd;
    sample2take(sample2take<1) = 1;
    sample2take(sample2take>length(data)) = length(data);
    single_trial_re(:,j) = data_re(sample2take);
    single_trial_re(:,j) = single_trial_re(:,j) - ...
        mean(single_trial_re(sample_base_twd,j));
end

subplot(2,3,3);
imagesc(t_axis,1:length(est_latency),single_trial_re(:,RS_accending_index(est_latency))');colormap(jet);
xlabel('time (ms)');ylabel('trials sorted by estimated latency');
title('Resynced single trials');
 
subplot(2,3,[4 5 6]);
plot(t_axis,ERP,'k');hold on;
plot(t_axis,ERP_re,'r');axis tight;
xlabel('time (ms)');ylabel('\muV');
ys = ylim;
h = fill([resync_twd(1),resync_twd(2),resync_twd(2),resync_twd(1)],...
    [ys(1),ys(1),ys(2),ys(2)],'g','linestyle','none');
set(h,'facealpha',.1);
uistack(h,'bottom');
legend({'ReSync window','Before ReSync','After ReSync'});

%wrap up
results.original_data = data;
results.resync_data = data_re;
results.est_latency = est_latency;
results.decomp_ERPs = ERPs;
results.original_ERP = ERP;
results.resync_ERP = ERP_re;
results.t = t_axis;
results.SNR = SNR;disp(['SNR:',num2str(SNR)]);
results.RLV = RLV;disp(['RLV:',num2str(RLV)]);
results.dominant_freq = dominant_freq;disp(['Dominant Frequency:',num2str(dominant_freq)]);
results.resync_flag = SNR > 0.3 && SNR > 0.3 + (0.175-RLV)*(1.2-0.3)/(0.175-0.025);
disp(['ReSync Flag:',num2str(results.resync_flag)]);
    


