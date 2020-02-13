% eegplugin_ReSync() - EEGLab plugin for resynchronizng single trial ERPs
%
% Inputs:
%   fig           - [integer]  EEGLAB figure
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



function vers = eegplugin_ReSync( fig,try_strings, catch_strings)

vers = 'ReSync1.0';

toolsmenu = findobj(fig, 'tag', 'tools');
h = uimenu(toolsmenu, 'label', 'ReSync', 'callback', ...
           [try_strings.no_check ...
           '[ALLEEG EEG CURRENTSET] = pop_ReSync( ALLEEG ,EEG ,CURRENTSET );'...
           catch_strings.add_to_hist]); 

