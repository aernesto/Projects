function fig_ = figBIAS_residSummary(num)
% function fig_ = figBIAS_residSummary(num)
%

if nargin < 1 || isempty(num)
    num = 4;
end

% units should be in inches, from wysifig
wid  = 6.5; % total width
hts  = 1.2;
cols = {4};
[axs,fig_] = getBIAS_axes(num, wid, hts, cols);

% get monkeys, colors
[monks, monkn, mse] = getBIAS_monks;

%%
% Get the data
%%
rsdat = FS_loadProjectFile('2008_Bias', 'figBIAS_residSummary');

if isempty(rsdat)

    rsdat  = cell(monkn, 4);
    fcs    = getBIAS_fcs;
    fun    = @ddExp2_L;
    acsz   = 100;

    for mm = 1:monkn

        dat          = FS_getDotsTrainingData(monks{mm});
        Lgood        = dat(:,2) <= 2 & dat(:,3)>=0 & isfinite(fcs{mm});% & dat(:,6)<0.8;
        L51          = dat(:,5) == 0.5120;
        L99          = dat(:,5) >  0.9;
        Lcor         = dat(:,3) == 1;
        sessions     = unique(dat(:,1));
        num_sessions = length(sessions);

        rsdat{mm,1} = nans(num_sessions, 4, 2);        % fits/sems
        rsdat{mm,2} = nans(num_sessions, 3, 2, 3);    % mean/median/sem; resid/chc/dir; DC/AC
        
        for ss = 1:num_sessions

            Lses  = Lgood & dat(:,1) == sessions(ss);
            disp([ss sessions(ss) sum(Lses)])

            % check 99 & 51 coh
            Ltm = Lses & dat(:,6) > nanmedian(dat(Lses,6));
            if sum(Ltm&L99&Lcor)/sum(Ltm&L99) < sum(Ltm&L51&Lcor)/sum(Ltm&L51)
                Lses = Lses & ~L99;
            end
    
            if sum(Lses) > 100

                % Get lapse rate
                lapse  = getSLOPE_lapse(dat(Lses, [3 5 6]));
                ltofit = min(0.2, max(lapse, 0.001));
                
                % fit to simple model
                [f1,s1,t1,p1,r1] = ctPsych_fit(fun, dat(Lses, [5 6 8 9]), ...
                    dat(Lses, 3), [], [], [], [], ltofit);
                % ctPsych_plot(fun1, f1, dat(Lses, [5 6 8 9]), dat(Lses, 3))
                
                rsdat{mm,1}(ss,:,  1) = [f1' lapse ctPsych_thresh(fun, f1)];
                rsdat{mm,1}(ss,1:2,2) = s1;
                
                vals = [r1(:,4) dat(Lses, [8 9])];
                for vv = 1:3
                    rsdat{mm,2}(ss,:,1,vv) = [nanmean(vals(:,vv)) nanmean(abs(vals(:,vv))) nanse(vals(:,vv))];
                    ac                     = xcorr(vals(:,vv), acsz, 'coeff');
                    rsdat{mm,2}(ss,:,2,vv) = [ac(acsz+2) ac(acsz+3) abs(mean(ac(acsz+(2:51))))];
                end
            end
        end
    end

    % save it to disk
    FS_saveProjectFile('2008_Bias', 'figBIAS_residSummary', rsdat);
end


gr = 0.4*ones(1,3);
sy = {'<' '*' 'o'};
for mm = 1:monkn
    ses = (1:mse(mm))';
    axes(axs(mm)); cla reset; hold on;
    %plot([0 0], [0 1], 'k:');
    
    % raw resids
    xs = abs(rsdat{mm,2}(ses,1,2,1));
    ys = abs(rsdat{mm,2}(ses,1,1,1));
    Lp = rsdat{mm,2}(ses,1,2,1)>0;
    disp([mm sum(Lp)./sum(isfinite(xs)).*100])
    plot(xs(Lp),  ys(Lp),  sy{1}, 'Color', gr, 'MarkerFaceColor', gr, 'MarkerSize', 5);
    plot(xs(~Lp), ys(~Lp), sy{1}, 'Color', gr, 'MarkerFaceColor', 0.99*ones(1,3), 'MarkerSize', 5);

    for vv = 1:3
        xs = abs(rsdat{mm,2}(ses,1,2,vv));
        ys = abs(rsdat{mm,2}(ses,1,1,vv));
        pcx = prctile(xs(isfinite(xs)), [25 50 75]);
        pcy = prctile(ys(isfinite(ys)), [25 50 75]);
        if vv == 1
            plot(pcx([2 2]), pcy([1 3]), 'k-', 'LineWidth', 1);
            plot(pcx([1 3]), pcy([2 2]), 'k-', 'LineWidth', 1);
        elseif vv == 2
            plot(pcx([2 2]), pcy([1 3]), 'k--', 'LineWidth', 1);
            plot(pcx([1 3]), pcy([2 2]), 'k--', 'LineWidth', 1);
        else
            plot(pcx([2 2]), pcy([1 3]), 'k-', 'LineWidth', 2);
            plot(pcx([1 3]), pcy([2 2]), 'k-', 'LineWidth', 2);
        end
        plot(pcx(2), pcy(2), sy{vv}, 'Color', 'k', 'MarkerFaceColor', 'k', 'MarkerSize', 9);
        axis([0 .3 0 .3]);
    end
end

return

for mm = 1:4
    ses = (1:mse(mm))';
    disp([sum(isfinite(rsdat{mm,2}(ses,1,2,1))) sum(rsdat{mm,2}(ses,1,2,1)>0) ...
        sum(rsdat{mm,2}(ses,1,2,1)>0)./sum(isfinite(rsdat{mm,2}(ses,1,2,1))).*100])
    subplot(1,4,mm); cla reset; hold on;
    plot([-.8 .8], [0 0], 'k:');
    plot([0 0], [-.8 .8], 'k:');
    plot(rsdat{mm,2}(ses,1,2,1), rsdat{mm,2}(ses,2,2,1), 'k.');
end

    
%% plotBIAS_residSummary does the work:
wid  = 0.30;
stp  = 1.25;
sep  = 0.33;
vals = [2 1; 4 0; 5 1];
wh1=plotBIAS_residSummary(rsdat(:,1), [], vals, 3, [],  0.55+(0:stp:stp*3),       wid, axs, [0.7 0.7 0.7]);
    plotBIAS_residSummary(rsdat(:,1), [], vals, 1, wh1, 0.55+sep*1+(0:stp:stp*3), wid, axs, [0 0 0]);
    plotBIAS_residSummary(rsdat(:,2), [], vals, 1, wh1, 0.55+sep*2+(0:stp:stp*3), wid, axs, [1 0 0]);
set(axs(3),'XTickLabel',{'At', 'Av', 'Cy', 'ZZ'})

return

%% OLD
wid  = 0.13;
stp  = 1.25;
sep  = 0.15;
%co   = (ones(3,1)*linspace(0.7,0,6))';
co   = [0.7 0.7 0.7; 0 0 0; 1 0 0; 0 1 0; 0 0 1; 1 0 1];
st   = {'--', '--', '-', '-', '-', '-'};
vals = [2 1; 4 0; 5 1];
wh1=plotBIAS_residSummary(rsdat(:,1), [], vals, 3, [], 0.55+(0:stp:stp*3), wid, axs, co(1,:),[]);
for ff = 1:size(rsdat,2)
    disp(funs{ff})
    if ff <= 2
        wh2=plotBIAS_residSummary(rsdat(:,ff), [], vals, 1, wh1, ...
            0.55+sep*ff+(0:stp:stp*3), wid, axs, co(ff+1,:),[]);
    else
        plotBIAS_residSummary(rsdat(:,ff), [], vals, 1, wh2, ...
            0.55+sep*ff+(0:stp:stp*3), wid, axs, co(ff+1,:),[]);
    end
end
set(axs(3),'XTickLabel',{'At', 'Av', 'Cy', 'ZZ'})
