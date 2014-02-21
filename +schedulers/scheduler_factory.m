function [ scheduler ] = scheduler_factory(config)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
    switch config.scheduler
        case 'round robin'
            scheduler = schedulers.LDACS_scheduler_round_robin(config);
        otherwise
            error('scheduler not supported')
    end

end

