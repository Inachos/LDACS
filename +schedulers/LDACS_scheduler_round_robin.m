classdef LDACS_scheduler_round_robin<schedulers.LDACS_scheduler
    %LDACS_SCHEDULER_ROUND_ROBIN Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = LDACS_scheduler_round_robin(config)
            obj = obj@schedulers.LDACS_scheduler(config);
        end
    end
    
end

