function [x_lim y_lim] = getlim(lines, threshold, pad)
    % [x_lim y_lim] = getlim(lines, threshold, pad)
    % 
    % Calculates limits for x and y axis. 
    if nargin < 2
        threshold = 0;
    end
    if nargin < 3
        pad = 0.2 * ones(4,1);
    end
    if isscalar(pad)
        pad = pad * ones(4,1);
    end
    for l = 1:length(lines)
        y_data = mean(lines(l).ydata,2);
        y_min(l) = min(y_data);
        y_max(l) = max(y_data);
        if (threshold > 0)
            msk = y_data > (y_min(l) + threshold * y_max(l));
            x_min(l) = lines(l).xdata(find(msk, 1, 'first'));
            x_max(l) = lines(l).xdata(find(msk, 1, 'last'));
        else
            x_min(l) = min(lines(l).xdata);
            x_max(l) = max(lines(l).xdata);
        end
    end
    x_range = max(x_max) - min(x_min);
    x_lim = [min(x_min) - pad(1) * x_range, ...
             max(x_max) + pad(3) * x_range];
    y_range = max(y_max) - min(y_min);
    y_lim = [min(y_min) - pad(2) * y_range, ...
             max(y_max) + pad(4) * y_range];
