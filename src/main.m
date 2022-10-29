%% Analysis of the IGE project data
% Multiple DVs, 3 groups, 3 epochs, looking for group-by-epoch interaction
% s.t. one group increases more than others on any DV.

%% Preamble
% First, clear the workspace and add the new functions to the path.  Then
% set the false alarm rate and decide whether to use Bonferroni correction.
% Then decide on priors.

clear
close all
addpath src

alpha = 0.05;
doBfc = true;

priors = struct( ...
    'mean', @(x)normpdf(x, 0.0, 1.0)  , ...
    'std' , @(x)gampdf (x, 2.0, 2.0)   ...
    );


%% Load and process data
% Raw data has a number of small deficiencies that need fixing.  For
% example, missing time stamps were imputed by using the time stamp of the
% previous index (iteratively if needed).  Multiplied values of DVs were
% deduplicated by assigning to the appropriate epoch.

data = fcn.preprocess( ...
    'data/raw.csv',    ...
    'data/processed.csv');
data.hours = log(data.hours + 1);


%% Loop over DVs to analyze independently
% Assumption of independence is most likely violated, so keep in mind this
% is a liberal test.

dvList = [ ...
    "advanced"           ...
    "milestones_cogsci"  ...
    "milestones_psysci"  ...
    "enjoy"              ...
    "good"               ...
    "nonexperts"         ...
    "discouraged"        ...
    "writers_block"      ...
    "inspired"           ...
    "cant_start"         ...
    "rejection"          ...
    "rcv_fdbk"           ...
    "gv_fdbk"            ...
    "timeblock"          ...
    "conference_submit"  ...
    "conference_accept"  ...
    "perma_hap"          ...
    "hours"              ];

nDvs = numel(dvList);

zs = nan(nDvs, 1);
results.Omnib = table( zs, zs, zs, zs, ...
    'RowNames', dvList, 'VariableNames', ["logLR" "df" "p" "h"]);
results.Group   = results.Omnib ;
results.Epoch   = results.Omnib ;

adjustedAlpha = alpha / (nDvs^doBfc);


%%

for dvName = dvList

    % First, plot the DVs in a standard ANOVA plot

    fcn.plotDv(data, dvName, gca);
    legend 'Group 1' 'Group 2' 'Group 3' 'Location' 'best'

    % Next, conduct an omnibus test of deviation from the global null
    % hypothesis that all 9 means are identical.  If this is met, there is
    % no need to look for interactions.

    stats = fcn.getStats(data, dvName, priors);

    globalLlik = fcn.globalLikelihood(stats);

    results.Omnib(dvName,:) = fcn.computeTestStats('Condition', ...
        stats, globalLlik, adjustedAlpha);

    results.Group(dvName,:) = fcn.computeTestStats('IV', ...
        stats, globalLlik, adjustedAlpha);

    results.Epoch(dvName,:) = fcn.computeTestStats('Epoch', ...
        stats, globalLlik, adjustedAlpha);

    fcn.writeReport(dvName, results, data)

end


%%

disp(results.Omnib)
writetable(results.Omnib, 'results/omnibus.csv', 'WriteRowNames', true)

disp(results.Group)
writetable(results.Group, 'results/group.csv', 'WriteRowNames', true)

disp(results.Epoch)
writetable(results.Epoch, 'results/epoch.csv', 'WriteRowNames', true)
