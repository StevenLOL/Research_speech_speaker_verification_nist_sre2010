function plot_dcf_curve(plot_obj,dcf,plot_args,legend_string)
% Plots a DCF curve for the current system.
% Inputs:
%   dcf: A vector of dcf values (actual or minimum).
%   plot_args: A cell array of arguments to be passed to 'plot'
%     that control the appearance of the curve. See Matlab's help
%     on 'plot' for information.
%   legend_string: Optional. A string to describe this curve in the
%     legend.  This string will be prepended with the system name.

if ischar(plot_args)
    plot_args = {plot_args};
end

figure(plot_obj.fh);
assert(iscell(plot_args))
lh = plot(plot_obj.plo,dcf,plot_args{:});

if exist('legend_string','var') && ~isempty(legend_string)
    assert(ischar(legend_string))
    plot_obj.add_legend_entry(lh,legend_string,true);
end

end
