classdef busclass < handle
    
  properties
    loadPower;  % the load the bus must satisfy (W)
  end
  
  events
    loadPowerChange; % notify whenever the load power changes
  end
  
  methods
    % constructor
    function obj = busclass()
        obj.loadPower = 0;
    end
    
    % setter - this is called each time a value is assigned to the property
    % loadPower 
    function set.loadPower(obj,power) 
      oldpower = obj.loadPower;
      obj.loadPower = power;
      if obj.loadPower ~= oldpower
        obj.notify('loadPowerChange');
      end
    end
  end
end