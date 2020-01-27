
function data = ReSync_w_lat(data,cfg,jitter)

%ReSyncing data with given latencies jitter (no need to estimate)
%data: n*m, n: number of channels; m: number of sampling points

est_latency = jitter;
srate = cfg.srate;
epoch_twd = cfg.epoch_twd;
base_twd = cfg.base_twd;
latencies = cfg.latencies;
n = size(data,1);m = size(data,2);

%handling error
for hand_e = 1:1
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

sample_twd = fix(epoch_twd(1)*srate/1000):fix(epoch_twd(2)*srate/1000);



%baseline
sample_base_twd = (round((base_twd(1)-epoch_twd(1))*srate/1000)+1):(round((base_twd(2)-epoch_twd(1))*srate/1000)+1);

if std(est_latency) ~= 0
    
regressor = zeros(length(sample_twd),m);
for j = 1:length(sample_twd)
    temp = latencies + sample_twd(j);
    temp(temp<1|temp>m) = [];
    regressor(j,temp) = 1;
end

regressor2 = zeros(length(sample_twd),m);
latencies2 = latencies + est_latency;
for j = 1:length(sample_twd)
    latencies_temp = latencies2 + sample_twd(j);
    latencies_temp(latencies_temp<1|latencies_temp>m) = [];
    regressor2(j,latencies_temp) = 1;
end
    
invR = inv([regressor;regressor2]*[regressor;regressor2]')*[regressor;regressor2];

fprintf('channels:');
for ch = 1:n
    fprintf([num2str(ch),' ']);
    data_ch = data(ch,:);

ERPs = invR*data_ch';
ERPs = reshape(ERPs,length(sample_twd),2);

%re-baseline (only do it once)
for j = 1:size(ERPs,2)
    ERPs(:,j) = ERPs(:,j) - mean(ERPs(sample_base_twd,j));
end

    
%%%reconstructing single trial ERP

ERP_re = sum(ERPs,2);

ST = ERPs(:,1)'*regressor;
ST2 = ERPs(:,2)'*regressor2;
ST_re = ERP_re'*regressor;

data(ch,:) = data_ch - ST - ST2 + ST_re;

end
fprintf('\n');
end

