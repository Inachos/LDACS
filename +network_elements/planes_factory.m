function [ planes ] = planes_factory(config, tower)
%PL Summary of this function goes here
%   Detailed explanation goes here
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

