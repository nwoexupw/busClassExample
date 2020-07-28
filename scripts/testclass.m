% Microgrids are power grids, of any size, that have several properties:
% 1. Power generation (usually multiple sources, such as pv panels, a few
% diesel generators, etc.)
% 2. Electrical loads (sometimes they can be managed - connected or
% disconnected from the 'bus' as needed
% 3. Abiltiy to connect or disconnect from other power grids. 
% 4. Some capacity to store energy (batteries, flywheels, etc.)
%
% Whenever several sources are connected to service a load, there are
% 'losses' The power isn't really lost, but there is some heat generation
% due to things like conductor resistance. This heat turns useful
% electrical energy into less useful heat. 
%
% This class allows several sources to be created and dynamically connected,
% or disconnected from the main bus. Each source has a voltage associated
% with it that can also change, as can the electrical load. 
%
% Given N sources, and a load, there is an optimal setting for the sources
% so they will meet the load while incurring the least amount of 'lost'
% energy due to conductor resistances. 
%
% The main purpose of this class is to dynamically compute the source power
% output settings as sources come and go, voltages change or the load
% changes. 
%
% The interesting technique exploited here is the notion of an 'event' and
% a 'listener'. A source connecting or disconnecting is an event. When that
% event occurs, it triggers a recompute of the optimal power settings of
% the available sources. This is an odd behavior if you are not familiar
% with this type of programming. For example, you change a variable in the
% base workspace and the value of some other quantity changes
% automatically. 
%
% This is a meager example to illustrate the concept. Once you become
% accustomed to it, you will likely conjur up all sorts of interesting ways
% to use it.

clearvars;
close('all');
clc;

% I was doing some debugging and left this in place
% to remind me how to set breakpoints from the command line...
%dbstop at 82 in allsources
%dbstop at 70 in allsources

% Make a bus object. At this point the bus load is zero.
busObj = busclass;

% Make an allsource object that listens to busObj for a load
% power change.
asObj = allsources(busObj);

% Make a bunch of sources and put their handles into an array
% for convenience. All the source voltages are zero at this point.
for i=1:5
  srcObj(i) = source;
end

% register 4 of the sources

for i=1:4
  asObj.Register(srcObj(i));
end

disp('At this point, there are 4, zero volt sources connected');
disp('to the bus whose power requirement is zero. We also have');
disp('one remaining source that is not registered, srcObj(5)');
disp('');

disp('Next, set the 4 registered sources voltages to:');
disp('20, 30, 40, 50');
disp('');

srcObj(1).voltage = 20;
srcObj(2).voltage = 30;
srcObj(3).voltage = 40;
srcObj(4).voltage = 50;

disp('Now set the bus load to 1kW and look at the source powers');
busObj.loadPower = 1000;
asObj.dispPwr(srcObj);

disp('Now change the bus load to 2kW and look at the source powers');
busObj.loadPower = 2000;
asObj.dispPwr(srcObj);

disp('Now remove (deregister) source 2 and then look at the powers');
asObj.deregister(srcObj(2));
asObj.dispPwr(srcObj);

disp('Now bring source 5 online and look at the powers');
asObj.Register(srcObj(5));
asObj.dispPwr(srcObj);
disp('The reason source 5 power is zero is because its voltage is 0');

disp('Set source 5 voltage to 80 and look at the powers');
srcObj(5).voltage = 80;
asObj.dispPwr(srcObj);