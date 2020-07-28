classdef source < handle
%
       
  properties       
    id;          % unique id assigned at registration with allsource
    voltage;     % source object's voltage
    resistance;  % source object's parasitic resistance
    mypwr;       % source object's optimal power output
    asrc;        % listener handle to allsource opt pwr den change 
  end
       
  events(ListenAccess = 'public', NotifyAccess = 'protected')
     vchg;          % voltage change
  end       
       
  methods
    function obj = source()
      obj.voltage = 0; % init the voltage
      obj.resistance = 1; % init the resistance
      obj.mypwr = 0;
    end
    % class constructor
    
    function id = get.id(obj)
      id = obj.id;              % We could execute other code as well.
    end
           
    function obj = set.voltage(obj,newv)
      oldvoltage = obj.voltage;
      obj.voltage = newv;
      if obj.voltage ~= oldvoltage
        obj.notify('vchg');
      end      
    end 
    
    % called by allsource object to make this source object listen
    % to allsource's "evtChangeLostPowerFraction" event.
    % "evtChangeLostPowerFraction" is notified by
    % the allsource object when it updates the denominator of the
    % optimal power apportionment solution:
    %
    %           v_i^2 P_{net}
    % P_i  = -------------------
    %         R_i \sum v_i^2/R_i
    %
    % Note: it's actually just updated the term:
    %
    %       P_{net}
    %    ---------------
    %    \sum v_i^2/R_i
    %
    % The argument allsrcobj is the allsource object making the
    % call and the argument allsrcevent is the string
    % "evtChangeLostPowerFraction"
    % 
    % When "evtChangeLostPowerFraction" is posted by the allsource
    % object, then 
    % cpwr is called. cpwr computes this source's new, optimal power
    % output (the equation above) based on the updated summation term.
    %
    function obj = listentome(obj,allsrcobj,allsrcevent)
      obj.asrc = addlistener(allsrcobj,allsrcevent,@(src,evnt)cpwr(obj,src,evnt));
    end
    
    function obj = cpwr(obj,src,evnt)
      obj.mypwr = obj.voltage^2 / obj.resistance * src.lostPowerFrac;
      %disp(['Source ',num2str(obj.id),' Power = ',num2str(obj.mypwr)]);
    end
           
  end
end
