function terminate = waitForNextTimeStep(t, liveParam)
% @author Florian Pfaff pfaff@kit.edu
% @date 2016-2022
% When using live mode, pause if not yet ready
currLockStatus = getLockStatus(liveParam.trackingLockFile);
stillLocked = true;
dispstat('', 'init');
startedWaitingAt = datetime;
terminate = false;
while isa(currLockStatus, 'char') && stillLocked && ~isnan(str2double(currLockStatus)) || (~isa(currLockStatus, 'char'))
    pause(0.1);
    currLockStatus = getLockStatus(liveParam.trackingLockFile);
    if (datetime - startedWaitingAt) > liveParam.maxWaitTime
        stillLocked = false;
        terminate = true;
        warning('LiveMode:Timeout', 'No new measurements for %s. Giving up...', string(liveParam.maxWaitTime));
    elseif (str2double(currLockStatus) - (t - 1) * liveParam.timeStepMultiplier) < eps(10000)
        dispstat('Waiting for next time step.', 'timestamp')
    elseif (str2double(currLockStatus) - t * liveParam.timeStepMultiplier) < eps(10000)
        stillLocked = false;
    elseif ~isnan(str2double(currLockStatus)) % Do not error if 'end' is written in file
        error('LiveMode:lostSync', ...
            'Time is not synchronized. Expected time step %5.5G or %5.5G, read in step %s', ...
            (t - 1)*liveParam.timeStepMultiplier, t*liveParam.timeStepMultiplier, currLockStatus);
    elseif ~isa(currLockStatus, 'char')
        warning('LiveMode:EmptyLockFile','Lock file was empty, trying again.');
    end
end
% Give warning and end execution
if contains(currLockStatus, 'end') % Use keyword end to terminate execution normally
    terminate = true;
end
end

function status = getLockStatus(fn)
file = fopen(fn);
status = fgetl(file);
fclose(file);
end