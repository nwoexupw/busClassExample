classdef allsources < handle

  % PROPERTIES  
  % 1. ids
  %    array of reg'd source ids
  % 2. voltages
  %    array of reg'd source voltages
  % 3. resistances
  %    array of reg'd source resistances
  % 4. lostPowerFrac
  %    since the allsource object has all the source and
  %    bus information, it keeps the term, used by the 
  %    sources to compute the optimal power setting, up to date.
  % 5. loadPower
  %    the most current bus object's loadPower requirement
  % 6. lshSourceVoltageChange
  %    array of listener handles to catch each
  %    source's voltage change. When a voltage change
  %    event is posted, then the lostPowerFrac property
  %    of the allsource oject is updated.
  % 7. lshBus
  %    listener handle to the busobject associated with
  %    this allsource object. When a bus load change
  %    event is posted, then the lostPowerFrac property is updated.    
  properties       
    ids;
    voltages;
    resistances;
    lostPowerFrac;
    loadPower;
    lshSourceVoltageChange;
    lshBus;
  end
   
  % EVENTS
  % 1. evtLostPowerFractionChanged
  %    This gets posted whenver the lostPowerFrac property has changed
  %    There are four possible reasons (1) a new source is
  %    registerd (2) a source is deregistered (3) a source's voltage
  %    changes (4) the bus's loadPower changes
  events(ListenAccess = 'public', NotifyAccess = 'protected')
    evtLostPowerFractionChanged;
  end       
  
  % PUBLIC METHODS
  % 1. allsource - constructor
  % 2. register - register a source
  % 3. deregister - deregister a source
  % 4. EvtUpdateLostPowerFraction - event that updates lost power fraction

  methods
    % ALLSOURCE  
    % Purpose: object constructor
    % Argument: busobject
    % Abstract: It leaves most of the properties as empty, execpt:
    %  lostPowerFrac - set to 0
    %  loadPower - set to the bus's loadPower value
    %  lshBus - this is a listener handle to the busobject's 
    %     loadPowerChange event. When the bus's loadPower value changes,
    %     a loadPowerChange notification is posted which causes the 
    %     allsource object to (1) update its loadPower value, update its
    %     lostPowerFraction property and notify all the sources that the
    %     lostPowerFraction has changed so they can change their power
    %     output to satisfy the new bus load.
    function obj = allsources(busobject)
      obj.lostPowerFrac = 0;        
      obj.loadPower = busobject.loadPower;
      obj.lshBus = addlistener(...
        busobject,...
        'loadPowerChange',...
        @(src,evnt)EvtUpdateLostPowerFraction(obj,src,evnt));
    end
    
    % REGISTER
    % Purpose: Register a source
    % Argument: source object
    % Abstract: Registering a source means that it is assigned a unique
    % id, and this id is logged into the allsource object's ids array.
    function obj = Register(obj,sourceobj)
        
      fini = false; % done flag
      
      % If the source arg already has an id, then the method does nothing
      % except give some feedback via the display. Note: the method only
      % checks the source's id, not the log in the allsource object. I
      % suppose it would be better to check both and toss an exception if
      % there is an inconsistency.
      if ~isempty(sourceobj.id)
        disp(['This source is already registered as ',num2str(sourceobj.id)]);
        return;
      end
      
      % It's the first source to be registered, so set the id to 1. This
      % block sets the ids property value, the other properties as set
      % near the bottom of the method.
      if isempty(obj.ids)
        idx = 1;
        obj.ids(idx) = 1;
        fini = true;           % jump to the rest of the reg'd actions
      end
      
      % It's the second source to be registered. There's one of two 
      % possibilities (1) the existing registered source's id is 1, or
      % it's something other than 1. If the existing registered source's
      % id is 1, then the new source's id should be set to 2. If it's not,
      % then make the new source's id 1. After setting the allsource's 
      % id, the new source's id is updated.
      if (~fini) && (length(obj.ids) == 1) % There's only one source reg'd.
        idx = 2;
        if obj.ids == 1                % It's id is 1
          obj.ids(idx) = 2;            % so set the new source's id to 2.
        else                           % It's id is not 1
          obj.ids(idx) = 1;            % so set the new source's id to 1
        end
        fini = true;           % jump to the rest of the reg'd actions
      end

      % It's the Nth source to be registered, so we need to find a 
      % unique id. We'll check if all the reg'd ids are sequential. If
      % they are, then we'll set the new source's id to the next highest.
      % I suppose we should if there's room on the low end, but this is
      % ok for now. If the reg'd ids are not sequential, then we'll find
      % the first spot where there's a gap and grab the lowest id from
      % the gap.
      if ~fini
        idx = length(obj.ids) + 1;            % number of reg'd ids
        dids = diff(obj.ids);                 % sequence of reg'd ids
        fdids = find(dids>1);                 % find gaps
        if isempty(fdids)                     % no gaps
          obj.ids(idx) = max(obj.ids)+1;      % make new id at the end
        else                                  % gaps exists
          obj.ids(idx) = obj.ids(fdids(1))+1; % make new id from the 1st gap
        end
      end
      
      % Here's the rest of the registration actions common to the 
      % conditional blocks above.
      sourceobj.listentome(obj,'evtLostPowerFractionChanged'); % make the source listen to allsources
      obj.voltages(obj.ids(idx)) = sourceobj.voltage;
      obj.resistances(obj.ids(idx)) = sourceobj.resistance;      
      sourceobj.id = obj.ids(idx);          % update the source object
      tmph = addlistener(...
        sourceobj,...
        'vchg',...
        @(src,evnt)EvtUpdateLostPowerFraction(obj,src,evnt));
      obj.lshSourceVoltageChange{obj.ids(idx)} = tmph;     
      obj.ids = sort(obj.ids);              % order the reg'd ids, lo-hi
      obj.LostPowerFraction;
      obj.notify('evtLostPowerFractionChanged');        
    end                                     
    %%%% END REGISTER %%%%
    
    % DEREGISTER
    % Purpose: remove a source from the register
    % Argument: source object
    % Abstract: find the source's id in the allsource object and remove
    % it, also make the argument source's id the empty set.
    function obj = deregister(obj,sourceobj)
      sid = sourceobj.id;                       % grab the arg source's id
      if isempty(sid)                           % it has no id
        disp('This source is not registered');  % nothing to do but gripe
        return;
      end    
      
      % the source has an id
      
      lid = find(obj.ids == sid);   % get the reg index of the source's id
      if isempty(lid)               % oops, its id was not registered
        disp('Unregistered ID - ID has been revoked'); % complain
        sourceobj.id = [];          % reset the source's id
      else                          % the source's id was registered
        % remove the source's id from the allsource registry
        tmpids = [obj.ids(1:lid-1) obj.ids(lid+1:end)];
        obj.voltages(sid) = 0;
        obj.resistances(sid) = 1;     
        delete(obj.lshSourceVoltageChange{sid});
        obj.ids = sort(tmpids);     % order the register, likely not nec.
        sourceobj.id = [];          % clr the source's id
        sourceobj.mypwr = 0;        % clr the source's power
        delete(sourceobj.asrc);     % clr the source's listener
        obj.LostPowerFraction;
        obj.notify('evtLostPowerFractionChanged');         
        %obj.den(obj,'dummy');
      end
    end

    % EVTUPDATELOSTPOWERFRACTION
    % Purpose: this event is called when either vchg or loadPowerChange
    %   are posted. 
    % Argument: source object, event source, event
    % Abstract: It updates the allsource object's lostPowerFraction and
    % then posts the notification that this quantity changed. The sources
    % catch the post and then update their power outputs.
    function EvtUpdateLostPowerFraction(obj,src,evnt)
      
      % Entered due to a voltage change in one of the sources  
      if strcmp(evnt.EventName,'vchg')
        obj.voltages(src.id) = src.voltage;
      end
      
      % Entered due to a bus load change
      if strcmp(evnt.EventName,'loadPowerChange')
        obj.loadPower = src.loadPower; 
      end
      
      % update the allsource object's lostPowerFraction
      obj.LostPowerFraction; 
      
      % post that this quantity changes so the sources can update their
      % power output
      obj.notify('evtLostPowerFractionChanged');      
    end
    
    % template getter function for reference
    function ids = get.ids(obj)
      ids = obj.ids;              
    end 
    
    function dispPwr(~,srcObj)
      for i=1:length(srcObj)
        disp(['Source ',num2str(i),' = ',num2str(srcObj(i).mypwr)]);
      end
    end
    
  end
  
  methods(Access = private)
    function LostPowerFraction(obj)
      tmp = sum(obj.voltages.^2 ./ obj.resistances);
      % At times, all source voltages might be zero. When that happens
      % the power apportionment equation is not defined. We ctch tha
      % senario here.
      if tmp==0
        obj.lostPowerFrac = 0; 
      else
        obj.lostPowerFrac = ...
          obj.loadPower / tmp;
      end
    end
  end
  
end

