function set_system(plot_obj,tar,non,sys_name)
% Sets the scores to be plotted.  This function must be called
% before plots are made for a system, but it can be called several
% times with different systems (with calls to plotting functions in
% between) so that curves for different systems appear on the same
% plot.  
% Inputs:
%   tar: A vector of calibrated target scores.
%   non: A vector of calibrated non-target scores.
%         Both are assumed to be of the form 
%
%               log P(data | target)
%       llr = ------------------------
%             log P(data | non-target)
%
%         where log is the natural logarithm.
%   sys_name: A string describing the system.  This string will be
%     prepended to the plot names in the legend e.g. if the system
%     name is 'sys1' and you plot an actual miss rate curve then
%     the legend entry for that curve will be 'sys1 actual miss
%     rate'.  You can pass an empty string to this argument or omit
%     it. 

assert(isvector(tar))
assert(isvector(non))
assert(length(tar)>0)
assert(length(non)>0)

if exist('sys_name','var') && ~isempty(sys_name)
    plot_obj.sys_name = sys_name;
else
    plot_obj.sys_name = '';
end
[plot_obj.actDCF,plot_obj.actPmiss,plot_obj.actPfa] = fast_actDCF(tar,non,plot_obj.plo,true);
[plot_obj.minDCF,plot_obj.minPmiss,plot_obj.minPfa] = fast_minDCF(tar,non,plot_obj.plo,true);

Pfa30 = 30/length(non);
plot_obj.dr30FA = find(plot_obj.minPfa>=Pfa30,1);  

Pmiss30 = 30/length(tar);
plot_obj.dr30Miss = find(plot_obj.minPmiss>=Pmiss30,1,'last');
end
