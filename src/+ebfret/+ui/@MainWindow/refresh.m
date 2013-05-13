function refresh(self, panel, index)
    % refresh(self, panel, index)
    % 
    % Replots axes in specified plot panel (one of {'series', 'ensemble'})
    switch panel
        case 'ensemble' 
            controls = self.controls;
            handles = self.handles;
            plots = self.plots;
            series = self.series;
            analysis = self.analysis;
            if (length(series) > 0) && (length(analysis) > 0)
                a = controls.ensemble.value;
                
                % clear plots
                plots = struct();
                
                % set state colors
                self.controls.colors.state = ...
                    ebfret.plot.line_colors(self.analysis(a).dim.states);

                % intialize other colors if unspecified
                if ~isfield(self.controls.colors, 'obs')
                    self.controls.colors.obs = [0.4, 0.4, 0.4];
                end
                if ~isfield(self.controls.colors, 'viterbi')
                    self.controls.colors.viterbi = [0.66, 0.33, 0.33];
                end
                
                % create observation histogram
                x = self.get_signal();
                x = cat(1,x{:});
                idx = find(isfinite(x));
                x = x(idx);

                pargs = struct();
                try
                    pargs.weights = cat(1, analysis(a).expect.z);
                    pargs.weights = pargs.weights(idx,:);
                    pargs.color = self.controls.colors.state;
                catch err
                    pargs.color = self.controls.colors.obs;
                end
                plots.ensemble.obs = ...
                    ebfret.plot.state_obs(x, pargs, ...
                                          'linestyle', '-');
                try
                    % create prior plots
                    u_m = analysis(a).prior.mu;
                    u_beta = analysis(a).prior.beta;
                    u_a = 0.5 .* analysis(a).prior.nu;
                    u_b = 0.5 ./ analysis(a).prior.W;
                    u_alpha = analysis(a).prior.A;
                    try
                        plots.ensemble.prior.mean = ...
                            ebfret.plot.state_mean(u_m, u_beta, u_a, u_b, ...
                                'xdata', {plots.ensemble.posterior.mean.xdata}, ...
                                'linestyle', '--', ...
                                'color', self.controls.colors.state);
                        plots.ensemble.prior.noise = ...
                            ebfret.plot.state_stdev(u_a, u_b, ...
                                'xdata', {plots.ensemble.posterior.noise.xdata}, ...
                                'linestyle', '--', ...
                                'color', self.controls.colors.state);
                        plots.ensemble.prior.dwell = ...
                            ebfret.plot.state_dwell(u_alpha, ...
                                'xdata', {plots.ensemble.posterior.dwell.xdata}, ...
                                'linestyle', '--', ...
                                'color', self.controls.colors.state);
                    catch err
                        plots.ensemble.prior.mean = ...
                            ebfret.plot.state_mean(u_m, u_beta, u_a, u_b, ...
                                'linestyle', '--', ...
                                'color', self.controls.colors.state);
                        plots.ensemble.prior.noise = ...
                            ebfret.plot.state_stdev(u_a, u_b, ...
                                'linestyle', '--', ...
                                'color', self.controls.colors.state);
                        plots.ensemble.prior.dwell = ...
                            ebfret.plot.state_dwell(u_alpha, ...
                                'linestyle', '--', ...
                                'color', self.controls.colors.state);
                    end
                catch err
                end

                % create posterior plots
                try
                    % update all posterior plots
                    ns = find(~[self.series.exclude]);
                    w_m = cat(2, analysis(a).posterior(ns).mu);
                    w_beta = cat(2, analysis(a).posterior(ns).beta);
                    w_a = 0.5 * cat(2, analysis(a).posterior(ns).nu);
                    w_b = 0.5 ./ cat(2, analysis(a).posterior(ns).W);
                    w_alpha = cat(3, analysis(a).posterior(ns).A);
                    plots.ensemble.posterior.mean = ...
                        ebfret.plot.state_mean(w_m, w_beta, w_a, w_b, ...
                                               'linestyle', '-', ...
                                               'color', self.controls.colors.state);
                    plots.ensemble.posterior.noise = ...
                        ebfret.plot.state_stdev(w_a, w_b, ...
                                                'linestyle', '-', ...
                                                'color', self.controls.colors.state);
                    E_tau = -1 ./ log(diag(ebfret.analysis.normalize(mean(w_alpha,3), 2)));
                    plots.ensemble.posterior.dwell = ...
                        ebfret.plot.state_dwell(w_alpha, ...
                                                'xdata', arrayfun(@(tau) exp(linspace(log(0.01 * tau), log(100 * tau), 101))', ...
                                                            E_tau(:)', 'UniformOutput', false), ...
                                                'linestyle', '-', ...
                                                'color', self.controls.colors.state);
                catch err
                    rethrow(err)
                end

                % store prior and posterior plots
                self.plots = plots;

                % set axis properties
                sph = handles.seriesPanel.handles;
                eph = handles.ensemblePanel.handles;

                % set logarithmic axis for dwell time plots
                set(sph.axes.dwell, 'XScale', 'log');
                set(eph.axes.dwell, 'XScale', 'log');

                % set axis limits for observations
                [x_lim, y_lim] = ...
                    ebfret.plot.get_lim(plots.ensemble.obs, ...
                        1e-3, [0.05, 0.05, 0.05, 0.15]);
                set(sph.axes.time, 'YLim', x_lim);
                set(sph.axes.obs, ...
                    'XLim', x_lim, 'YLim', y_lim, ...
                    'YTick', linspace(y_lim(1), y_lim(2), 5));
                set(eph.axes.obs, ...
                    'XLim', x_lim, 'YLim', y_lim, ...
                    'YTick', linspace(y_lim(1), y_lim(2), 5));

                % % set axis limits for prior / posterior plots
                % if ~isempty(analysis(a).posterior)
                %     dist = 'posterior';
                % elseif ~isempty(analysis(a).prior)
                %     dist = 'prior';            
                % else
                %     dist = '';
                % end

                % axes = {'mean', 'noise', 'dwell'};
                % thresholds = [0.05, 0.2, 0.001];
                % for ax = 1:length(axes)
                %     dist = {'prior', 'posterior'};
                %     for d = 1:length(dist)
                %         try 
                %         catch err
                %         end
                %     end
                % end
                
                % update ensemble plots
                handles = self.handles;
                set_plots(handles.ensemblePanel, ...
                    'obs', plots.ensemble.obs);
                
                % get occupancy dependent scaling
                if self.controls.scale_plots
                    scale = mean(cat(1, analysis(a).expect.z),1);
                else
                    scale = 1;
                end

                axes = {'mean', 'noise', 'dwell'};
                thresholds = [0.02, 0.02, 0.001];
                for ax = 1:length(axes)
                    clear_plots(handles.ensemblePanel, axes{ax});
                    ax_plots = struct([]);
                    if isfield(plots.ensemble, 'posterior')
                        mean_post = plots.ensemble.posterior.(axes{ax});
                        for p = 1:length(plots.ensemble.posterior.(axes{ax}))
                            mean_post(p).ydata = mean(mean_post(p).ydata, 2);
                        end
                        ax_plots = cat(1, ax_plots, ...
                            ebfret.plot.scale(mean_post(:), scale));
                    end
                    if isfield(plots.ensemble, 'prior')
                        ax_plots = cat(1, ax_plots, ...
                            ebfret.plot.scale(plots.ensemble.prior.(axes{ax})(:), scale));
                    end
                    if ~isempty(ax_plots)
                        % set axis limits
                        [x_lim, y_lim] = ...
                            ebfret.plot.get_lim(ax_plots, ...
                                thresholds(ax), [0.05, 0.05, 0.05, 0.25]);
                        if strcmp(axes{ax}, 'dwell')
                            x_lim = [max(1e-4 * x_lim(2), x_lim(1)), x_lim(2)];
                            % y_lim = [2e-3 * y_lim(2), 2 * y_lim(2)];
                        end
                        set(eph.axes.(axes{ax}), ...
                            'XLim', x_lim, 'YLim', y_lim, ...
                            'YTick', linspace(y_lim(1), y_lim(2), 5));
                        % update plots
                        set_plots(handles.ensemblePanel, ...
                            axes{ax}, ax_plots);
                    end
                end

                % sync axis limits of series plots with esenmble plots
                axes = fieldnames(eph.axes);
                for ax = 1:length(axes)
                    x_lim = get(eph.axes.(axes{ax}), 'xlim');
                    y_lim = get(eph.axes.(axes{ax}), 'ylim');
                    set(sph.axes.(axes{ax}), ...
                        'XLim', x_lim, 'YLim', y_lim, ...
                        'YTick', linspace(y_lim(1), y_lim(2), 5));
                end

                % update time series plots
                self.refresh('series');
            else
                clear_plots(handles.ensemblePanel, ...
                    {'obs', 'mean', 'noise', 'dwell'});
            end
        case 'series'
            controls = self.controls;
            plots = self.plots;
            series = self.series;
            handles = self.handles;
            if length(self.analysis) > 0
                analysis = self.analysis(self.controls.ensemble.value);
            else
                analysis = struct([]);
            end
            clear_plots(handles.seriesPanel);
            if (length(series) > 0) & (self.controls.series.value > 0)
                n = self.controls.series.value;

                % generate time series plot and observation histogram
                plots.series = struct();
                sph = handles.seriesPanel.handles;
                x = series(n).signal(series(n).clip.min:series(n).clip.max);
                t = series(n).time(series(n).clip.min:series(n).clip.max);
                x_lim = get(sph.axes.obs, 'XLim');
                x_bins = linspace(x_lim(1), x_lim(end), ...
                            max(10, min(length(x)/10, 200)));
                if ~isempty(analysis)
                    pargs = struct();
                    try
                        pargs.weights = analysis.expect(n).z;
                        pargs.color = self.controls.colors.state;
                    catch err
                        pargs.color = self.controls.colors.obs; 
                    end
                    plots.series.obs = ebfret.plot.state_obs(...
                        x, pargs, ...
                        'xdata', x_bins, ...
                        'linestyle', '-');
                    try
                        pargs.state = analysis.viterbi(n).state;
                        pargs.mean = analysis.viterbi(n).mean;
                        pargs.color = {self.controls.colors.obs, ...
                                       self.controls.colors.viterbi, ...
                                       self.controls.colors.state{:}};
                    catch err
                        if isfield(pargs, 'weights')
                            pargs.color = {self.controls.colors.obs, ...
                                           self.controls.colors.viterbi, ...
                                           self.controls.colors.state{:}};
                        else
                            pargs.color = {self.controls.colors.obs};
                        end
                    end
                    plots.series.time = ebfret.plot.time_series(...
                        x(:), 'xdata', t(:), pargs, ...
                        'markersize', 4);

                    % update posterior plots
                    try
                        if self.controls.scale_plots
                            scale = mean(analysis.expect(n).z, 1);
                        else
                            scale = 1;
                        end
                        w = analysis.posterior(n);
                        plots.series.mean = ...
                            ebfret.plot.scale(...,
                                ebfret.plot.state_mean(...
                                    w.mu, w.beta, 0.5 * w.nu, 0.5 ./ w.W, ...
                                    'xdata', {self.plots.ensemble.prior.mean.xdata}, ...
                                    'linestyle', '-', ...
                                    'color', self.controls.colors.state), ...
                                scale);
                        plots.series.noise = ...
                            ebfret.plot.scale(...,
                                ebfret.plot.state_stdev(...
                                    0.5 * w.nu, 0.5 ./ w.W, ...
                                    'xdata', {self.plots.ensemble.prior.noise.xdata}, ...
                                    'linestyle', '-', ...
                                    'color', self.controls.colors.state), ...
                                scale);
                        plots.series.dwell = ...
                            ebfret.plot.scale(...,
                                ebfret.plot.state_dwell(...
                                    w.A, ...
                                    'xdata', {self.plots.ensemble.prior.dwell.xdata}, ...
                                    'linestyle', '-', ...
                                    'color', self.controls.colors.state), ...
                                scale);
                    catch err
                        rethrow(err)
                    end
                else
                    plots.series.time = ebfret.plot.time_series(...
                        x(:), 'xdata', t(:), ...
                        'color', {self.controls.colors.obs});
                    plots.series.obs = ebfret.plot.state_obs(...
                        x, 'xdata', x_bins, ...
                        'linestyle', '-', ...
                        'color', self.controls.colors.obs);
                end
                % update time series x-axis limits
                set(sph.axes.time, 'XLim', [min(t), max(t)]);
                % update time series plot
                set_plots(handles.seriesPanel, plots.series)
                self.plots = plots;
            end
    end
end