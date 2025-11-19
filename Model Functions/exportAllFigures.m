function exportAllFigures(figDir)
% exportAllFigures Export all open figures to PDF files in a folder
%   exportAllFigures(figDir) saves every open figure as a PDF file
%   inside the folder specified by figDir. If figDir is omitted or empty,
%   a folder named 'Figures' in the current working directory is used.

if nargin < 1 || isempty(figDir)
    figDir = fullfile(pwd,'Figures');
end

if ~exist(figDir,'dir')
    mkdir(figDir);
end

figs = findall(0,'Type','figure');
if isempty(figs)
    fprintf('exportAllFigures: no open figures to export.\n');
    return
end

% Filenames will not include timestamps so exported PDFs overwrite
% previous runs (per user request).

for k = 1:numel(figs)
    fig = figs(k);
    % Figure number and (optional) name
    fnum = fig.Number;
    fname = strtrim(fig.Name);
    if isempty(fname)
        fname = sprintf('Figure%d', fnum);
    end
    % sanitize filename (replace disallowed chars with underscore)
    safeName = regexprep(fname,'[^a-zA-Z0-9_\-]','_');
    base = sprintf('Fig%03d_%s', fnum, safeName);

    pdffile = fullfile(figDir, [base, '.pdf']);

    try
        % Prefer exportgraphics (R2020a+) for high-quality PDF output and
        % background control. Ensure all text/label/tick colors are black
        % so they remain readable on the white background. If not
        % available, fall back to print.
        %
        % Collect handles and backup properties to restore after export.
        axesHandles = findall(fig,'type','axes');
        textHandles = findall(fig,'type','text');
        legendHandles = findall(fig,'type','legend');
        colorbarHandles = findall(fig,'type','colorbar');

        % Backup properties
        oldFigColor = get(fig,'Color');
        oldIHC = get(fig,'InvertHardcopy');
        oldAxes = struct();
        for ai = 1:numel(axesHandles)
            ax = axesHandles(ai);
            oldAxes(ai).Color = get(ax,'Color');
            oldAxes(ai).XColor = get(ax,'XColor');
            oldAxes(ai).YColor = get(ax,'YColor');
            try
                oldAxes(ai).ZColor = get(ax,'ZColor');
            catch
                oldAxes(ai).ZColor = [];
            end
            % labels and title
            try oldAxes(ai).TitleColor = get(get(ax,'Title'),'Color'); catch, oldAxes(ai).TitleColor = []; end
            try oldAxes(ai).XLabelColor = get(get(ax,'XLabel'),'Color'); catch, oldAxes(ai).XLabelColor = []; end
            try oldAxes(ai).YLabelColor = get(get(ax,'YLabel'),'Color'); catch, oldAxes(ai).YLabelColor = []; end
            try oldAxes(ai).ZLabelColor = get(get(ax,'ZLabel'),'Color'); catch, oldAxes(ai).ZLabelColor = []; end
        end
        % Backup text colors
        oldTextColors = cell(1,numel(textHandles));
        for tI = 1:numel(textHandles)
            try
                oldTextColors{tI} = get(textHandles(tI),'Color');
            catch
                oldTextColors{tI} = [];
            end
        end
        % Backup legend text colors and background/boxface if present
        oldLegendTextColors = cell(1,numel(legendHandles));
        oldLegendProps = struct();
        for lI = 1:numel(legendHandles)
            try
                oldLegendTextColors{lI} = get(legendHandles(lI),'TextColor');
            catch
                oldLegendTextColors{lI} = [];
            end
            % Backup legend color (background) if available
            try
                oldLegendProps(lI).Color = get(legendHandles(lI),'Color');
            catch
                oldLegendProps(lI).Color = [];
            end
            % Backup BoxFace properties for newer MATLAB versions
            try
                bf = legendHandles(lI).BoxFace;
                oldLegendProps(lI).BoxFaceColor = get(bf,'Color');
                oldLegendProps(lI).BoxFaceEdge = get(bf,'EdgeColor');
                oldLegendProps(lI).BoxFaceColorType = get(bf,'ColorType');
            catch
                oldLegendProps(lI).BoxFaceColor = [];
                oldLegendProps(lI).BoxFaceEdge = [];
                oldLegendProps(lI).BoxFaceColorType = [];
            end
        end
        % Backup colorbar colors
        oldColorbarColors = cell(1,numel(colorbarHandles));
        for cI = 1:numel(colorbarHandles)
            try
                oldColorbarColors{cI} = get(colorbarHandles(cI),'Color');
            catch
                oldColorbarColors{cI} = [];
            end
        end

        % Set white background and black text/colors for readability
        % Only change text/label/title/tick/legend text colors to black and
        % set the figure background to white. Avoid changing defaults or
        % arbitrary objects' FontColor properties so plot element colors
        % (patches, pie slices, colormaps) are preserved.
        set(fig,'Color','white','InvertHardcopy','off');
        for aJ = 1:numel(axesHandles)
            ax = axesHandles(aJ);
            try
                set(ax,'Color','white','XColor','k','YColor','k');
            catch
            end
            try
                set(ax,'ZColor','k');
            catch
            end
            try
                set(get(ax,'Title'),'Color','k');
            catch
            end
            try
                set(get(ax,'XLabel'),'Color','k');
            catch
            end
            try
                set(get(ax,'YLabel'),'Color','k');
            catch
            end
            try
                set(get(ax,'ZLabel'),'Color','k');
            catch
            end
        end
        for tJ = 1:numel(textHandles)
            try
                set(textHandles(tJ),'Color','k');
            catch
            end
        end
        for lJ = 1:numel(legendHandles)
            try
                set(legendHandles(lJ),'TextColor','k');
            catch
            end
            % Force legend background to white where possible
            try
                set(legendHandles(lJ),'Color','white');
            catch
            end
            try
                bf = legendHandles(lJ).BoxFace;
                try set(bf,'ColorType','truecoloralpha'); catch; end
                try set(bf,'Color',[1 1 1]); catch; end
                try set(bf,'EdgeColor','none'); catch; end
            catch
            end
        end
        for cJ = 1:numel(colorbarHandles)
            try
                set(get(colorbarHandles(cJ),'Label'),'Color','k');
            catch
            end
        end

        try
            if exist('exportgraphics','file')==2
                exportgraphics(fig,pdffile,'ContentType','vector','BackgroundColor','white');
            else
                % Use print to create high-quality PDF
                print(fig, '-dpdf', pdffile, '-r0');
            end
        catch ME
            % Attempt to restore before rethrowing
            try
                % restore in a safe way
                try
                    set(fig,'Color',oldFigColor,'InvertHardcopy',oldIHC);
                catch
                end
                for aj = 1:numel(axesHandles)
                    ax = axesHandles(aj);
                    try
                        set(ax,'Color',oldAxes(aj).Color);
                    catch
                    end
                    try
                        set(ax,'XColor',oldAxes(aj).XColor);
                    catch
                    end
                    try
                        set(ax,'YColor',oldAxes(aj).YColor);
                    catch
                    end
                    try
                        if ~isempty(oldAxes(aj).ZColor)
                            set(ax,'ZColor',oldAxes(aj).ZColor);
                        end
                    catch
                    end
                    try
                        if ~isempty(oldAxes(aj).TitleColor)
                            set(get(ax,'Title'),'Color',oldAxes(aj).TitleColor);
                        end
                    catch
                    end
                    try
                        if ~isempty(oldAxes(aj).XLabelColor)
                            set(get(ax,'XLabel'),'Color',oldAxes(aj).XLabelColor);
                        end
                    catch
                    end
                    try
                        if ~isempty(oldAxes(aj).YLabelColor)
                            set(get(ax,'YLabel'),'Color',oldAxes(aj).YLabelColor);
                        end
                    catch
                    end
                    try
                        if ~isempty(oldAxes(aj).ZLabelColor)
                            set(get(ax,'ZLabel'),'Color',oldAxes(aj).ZLabelColor);
                        end
                    catch
                    end
                end
                for tj = 1:numel(textHandles)
                    try
                        set(textHandles(tj),'Color',oldTextColors{tj});
                    catch
                    end
                end
                for lj = 1:numel(legendHandles)
                    try
                        val = oldLegendTextColors{lj};
                        if ~isempty(val)
                            set(legendHandles(lj),'TextColor',val);
                        end
                    catch
                    end
                end
                for cj = 1:numel(colorbarHandles)
                    try
                        val = oldColorbarColors{cj};
                        if ~isempty(val)
                            % restore colorbar face/background color if it was set
                            set(colorbarHandles(cj),'Color',val);
                        end
                    catch
                    end
                    try
                        set(get(colorbarHandles(cj),'Label'),'Color',oldColorbarColors{cj});
                    catch
                    end
                end
            catch
            end
            rethrow(ME);
        end

        % Restore previous properties (normal path)
        try
            set(fig,'Color',oldFigColor,'InvertHardcopy',oldIHC);
        catch
        end
        for aj = 1:numel(axesHandles)
            ax = axesHandles(aj);
            try
                set(ax,'Color',oldAxes(aj).Color);
            catch
            end
            try
                set(ax,'XColor',oldAxes(aj).XColor);
            catch
            end
            try
                set(ax,'YColor',oldAxes(aj).YColor);
            catch
            end
            try
                if ~isempty(oldAxes(aj).ZColor)
                    set(ax,'ZColor',oldAxes(aj).ZColor);
                end
            catch
            end
            try
                if ~isempty(oldAxes(aj).TitleColor)
                    set(get(ax,'Title'),'Color',oldAxes(aj).TitleColor);
                end
            catch
            end
            try
                if ~isempty(oldAxes(aj).XLabelColor)
                    set(get(ax,'XLabel'),'Color',oldAxes(aj).XLabelColor);
                end
            catch
            end
            try
                if ~isempty(oldAxes(aj).YLabelColor)
                    set(get(ax,'YLabel'),'Color',oldAxes(aj).YLabelColor);
                end
            catch
            end
            try
                if ~isempty(oldAxes(aj).ZLabelColor)
                    set(get(ax,'ZLabel'),'Color',oldAxes(aj).ZLabelColor);
                end
            catch
            end
        end
        for tj = 1:numel(textHandles)
            try
                set(textHandles(tj),'Color',oldTextColors{tj});
            catch
            end
        end
        for lj = 1:numel(legendHandles)
            try
                val = oldLegendTextColors{lj};
                if ~isempty(val)
                    set(legendHandles(lj),'TextColor',val);
                end
            catch
            end
            % Restore legend background/boxface
            try
                if isfield(oldLegendProps, 'Color') && ~isempty(oldLegendProps(lj).Color)
                    set(legendHandles(lj),'Color',oldLegendProps(lj).Color);
                end
            catch
            end
            try
                bf = legendHandles(lj).BoxFace;
                if ~isempty(oldLegendProps(lj).BoxFaceColor)
                    try set(bf,'Color',oldLegendProps(lj).BoxFaceColor); catch; end
                end
                if ~isempty(oldLegendProps(lj).BoxFaceEdge)
                    try set(bf,'EdgeColor',oldLegendProps(lj).BoxFaceEdge); catch; end
                end
                if ~isempty(oldLegendProps(lj).BoxFaceColorType)
                    try set(bf,'ColorType',oldLegendProps(lj).BoxFaceColorType); catch; end
                end
            catch
            end
        end
        for cj = 1:numel(colorbarHandles)
            try
                val = oldColorbarColors{cj};
                if ~isempty(val)
                    set(colorbarHandles(cj),'Color',val);
                end
            catch
            end
            try
                set(get(colorbarHandles(cj),'Label'),'Color',oldColorbarColors{cj});
            catch
            end
        end

        % No global defaults or FontColor properties were modified, so
        % nothing extra to restore here.

        fprintf('exportAllFigures: saved %s\n', pdffile);
    catch ME
        warning('exportAllFigures:saveFailed','Failed to save figure %d: %s', fnum, ME.message);
    end
end

end