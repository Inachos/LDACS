function [ planes ] = planes_factory(config, tower)
%     This file is part of L-DACS simulator.
% 
%     L-DACS simulator is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     L-DACS simulator is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with  L-DACS simulator.  If not, see <http://www.gnu.org/licenses/>.
    for planes_idx = 1:config.nr_planes
        if 1 == mod(planes_idx, 2)
            side = 'upper';
        else
            side = 'lower';
        end
        planes(planes_idx) = network_elements.plane(config,...
            tower, planes_idx, side);
    end

end

