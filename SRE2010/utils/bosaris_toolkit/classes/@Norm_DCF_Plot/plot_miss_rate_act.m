function plot_miss_rate_act(plot_obj,plot_args,legend_string)
% Plots the contribution of the misses to the actual dcf curve.
% Inputs:
%   plot_args: A cell array of arguments to be passed to 'plot' that control
%     the appearance of the curve. See Matlab's help on 'plot' for information.
%   legend_string: Optional. A string to describe this curve in the legend.
%     This string will be prepended with the system name.

if ~exist('legend_string','var')
    legend_string = '';
end

plot_obj.plot_miss_rate(plot_obj.actPmiss,plot_args,legend_string);
end
