% pop_ReSync() - graphical interface of ReSync
%
% Usage:
%   >> [ALLEEG,EEG,CURRENTSET,com] = pop_ReSync(ALLEEG,EEG,CURRENTSET );
%
% Inputs: 
%   ALLEEG      - array of EEG dataset structures
%    EEG        - current dataset structure or structure array
%                  (EEG.reject.gcompreject will be updated)  
%    CURRENTSET - index(s) of the current EEG dataset(s) in ALLEEG
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


function [ALLEEG EEG CURRENTSET] = pop_ReSync(ALLEEG, EEG, CURRENTSET);
h = figure('name', 'ReSync','numbertitle', 'off','MenuBar', 'none',...
    'units','normalized','position',[0.4,0.1,0.3,0.8]);

data.epoch_twd = [-200,1000];
data.base_twd = [-200,0];
data.resync_twd = [300,800];
% data.lowpass_freq = 8;
guidata(h,data);

ElecButton = uicontrol(h, 'Style', 'pushbutton', 'Units','Normalized', 'Position',...
    [0.1 .9 0.8 0.05],'String', 'Select Electrode(s)','Callback', @select_elec);
data.elec_label = {EEG.chanlocs.labels};
guidata(h,data);

MarkerButton = uicontrol(h, 'Style', 'pushbutton', 'Units','Normalized', 'Position',...
    [0.1 .8 0.8 0.05],'String', 'Select Marker(s)','Callback', @select_marker);
for j = 1:length(EEG.event) EEG.event(j).type = char(string(EEG.event(j).type));end
data.marker_label = unique({EEG.event.type});
guidata(h,data);

ERPButton = uicontrol(h, 'Style', 'pushbutton', 'Units','Normalized', 'Position',...
    [0.1 .7 0.8 0.05],'String', 'Plot average ERP','Callback','RS_plotERP(EEG,guidata(gcf));');

pnl = uipanel(h,'Units','Normalized','Position',...
    [.1, .2 .8 .45]);

EpochLabel = uicontrol(h, 'Style', 'text', 'Units','Normalized', 'Position',...
    [.15 0.6 0.4 0.03],'String', 'Epoch Time Window:');

EpochEdit = uicontrol(h,'style','Edit','Units','normalized','Position',...
    [.55 0.6 0.3 0.03],'string',num2str(data.epoch_twd),'callback',@update_epochtwd);

BaseLabel = uicontrol(h, 'Style', 'text', 'Units','Normalized', 'Position',...
    [.15 0.55 0.4 0.03],'String', 'Baseline Time Window:');

BaseEdit = uicontrol(h,'style','Edit','Units','normalized','Position',...
    [.55 0.55 0.3 0.03],'string',num2str(data.base_twd),'callback',@update_basetwd);

ResyncLabel = uicontrol(h, 'Style', 'text', 'Units','Normalized', 'Position',...
    [.15 0.50 0.4 0.03],'String', 'ReSync Time Window:');

ResyncEdit = uicontrol(h,'style','Edit','Units','normalized','Position',...
    [.55 0.50 0.3 0.03],'string',num2str(data.resync_twd),'callback',@update_resynctwd);

% LowpassLabel = uicontrol(h, 'Style', 'text', 'Units','Normalized', 'Position',...
%     [.15 0.45 0.4 0.03],'String', 'Low-pass Frequency:');
% 
% LowpassEdit = uicontrol(h,'style','Edit','Units','normalized','Position',...
%     [.55 0.45 0.3 0.03],'string',num2str(data.lowpass_freq),'callback',@update_lowpass_freq);

ResyncButton = uicontrol(h, 'Style', 'pushbutton', 'Units','Normalized', 'Position',...
    [0.2 .35 0.6 0.1],'String', 'ReSync','BackgroundColor',[153, 204, 255]/255,...
    'callback','data = guidata(gcf);data.glb = 0;guidata(gcf,data);RS_resyncERP(EEG,guidata(gcf));');

ResyncGlbButton = uicontrol(h, 'Style', 'pushbutton', 'Units','Normalized', 'Position',...
    [0.2 .25 0.6 0.05],'String', {'ReSync Globally'},...
    'callback',['data = guidata(gcf);data.glb = 1;guidata(gcf,data);'...
                'EEG0 = RS_resyncERP(EEG,guidata(gcf));'...
                'EEG0.setname = [''ReSynced_'',num2str(length(EEG0.ReSync))];'...
                '[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG0, CURRENTSET);'...
                'eeglab(''redraw'');clear ''EEG0'';']);





function select_elec(src,event,handle)
data = guidata(src);
[indx,tf] = listdlg('ListString',data.elec_label);
data.elec_indx = indx;
guidata(src,data);

function select_marker(src,event,handle)
data = guidata(src);
[indx,tf] = listdlg('ListString',data.marker_label);
data.marker_indx = indx;
guidata(src,data);

function update_epochtwd(src,event,handle)
data = guidata(src);
data.epoch_twd = str2num(get(src,'string'));
guidata(src,data)

function update_basetwd(src,event,handle)
data = guidata(src);
data.base_twd = str2num(get(src,'string'));
guidata(src,data)

function update_resynctwd(src,event,handle)
data = guidata(src);
data.resync_twd = str2num(get(src,'string'));
guidata(src,data)

% function update_lowpass_freq(src,event,handle)
% data = guidata(src);
% data.lowpass_freq = str2num(get(src,'string'));
% guidata(src,data)


