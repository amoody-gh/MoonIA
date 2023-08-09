function [roiPositions, varargout] = mask2roi(mask, varargin)
% Designed and written by Alexander J. Moody, MS, PhD
% Please seek proper permissions from the author before disseminating or
% rewriting and republishing this function

% DESCRIPTION: 
% mask2roi converts binary images/masks into roi positions. Only one input
% is required for default algorithm, the mask. This mask can have any
% number of regions which will be contained in separate cells of the
% output. Additional outputs are perimeters (masks of edges) for each
% region. The points are lined up to be used in drawpolygon as shown below:

% EXAMPLE:
% roiPositions = mask2roi(mask)
% for i = 1:length(roiPositions)
%   drawpolygon("Position", roiPositions{i}, "Parent", imageAxes)
% end

% INPUTS:
% mask - logical - binary image
% NumROIs - numeric/int - specify the number of ROIs you want returned
% Connectivity - numeric - must be 4 or 8
% FillHoles - logical - in case you don't want holes filled in mask
% ScaleNumVertices - numeric/int - higher numbers remove more points
% RoundOutput - logical - rounds vertex coordinates

% OUTPUTS:
% roiPositions - cell of double arrays - arrays are n-by-2 where n is the
% number of regions in the mask, x and y correspond to col 1 and 2
% perimeters - optional - cell of 2D double arrays - Each with an edge mask
% of the individual regions

% Validate mandatory input
validateattributes(mask, ...
    {'logical'}, ...
    {'2d', 'binary', 'nonempty'})

% Set default values
setDefaults()

% Process Name-Value pairs
if(nargin > 1)
    for i = 1:2:length(varargin)
        switch varargin{i}
            case "NumROIs"
                numroi = varargin{i+1};
                validateattributes(numroi, ...
                    {'numeric'}, ...
                    {'positive', 'integer', 'scalar'})
            case "Connectivity"
                conn = varargin{i+1};
                validateattributes(conn, ...
                    {'numeric'}, ...
                    {'scalar', 'integer', 'positive'})
                if(~any(conn == [4, 8]))
                    warning("Connectivity must be either 4 or 8. Setting value at default of 4.")
                    conn = 4;
                end
            case "FillHoles"
                fillHoles = varargin{i+1};
                validateattributes(fillHoles, ...
                    {'logical'}, ...
                    {'scalar'})
            case "ScaleNumVertices"
                npScale = varargin{i+1};
                validateattributes(npScale, ...
                    {'numeric'}, ...
                    {'scalar', 'integer', 'positive'})
            case "RoundOutput"
                roundOut = varargin{i+1};
                validateattributes(roundOut, ...
                    {'logical'}, ...
                    {'scalar'})
            otherwise
                error(strcat("Unrecognized Name-Value Input: '", ...
                    varargin{i}, "' of type ", ...
                    convertCharsToStrings(class(varargin{i+1}))))
        end
    end
end

% Main Function Body
if(fillHoles)
    mask = imfill(mask, "holes");
end

% start by labeling regions
mask = bwareaopen(mask, 3, conn);
labs = bwlabel(mask, conn);
numLabs = max(labs, [], "all");

% check to see how many ROI's are requested
if(numroi == 0) % all ROI's will be drawn    
    roiPositions = cell(1, numLabs);
    perimeters = cell(1, numLabs);

    for i = 1:numLabs
        currRegion = labs == i;
        perimeters{i} = edge(currRegion);

        [posy, posx] = find(perimeters{i});
        roi = sortPoints([posx, posy]);

        scale = 1:npScale:size(roi, 1);
        roiPositions{i} = roi(scale, :);
    end
else % user defined number or rois
    if(numLabs > numroi)
        warning("More regions exist within the mask than are requested by the user. Truncation of output cells may occur.")
    end
    roiPositions = cell(1, numroi);
    perimeters = cell(1, numroi);

    for i = 1:numroi
        currRegion = labs == i;
        perimeters{i} = edge(currRegion);

        [posy, posx] = find(perimeters{i});
        roi = sortPoints([posx, posy]);

        scale = 1:npScale:size(roi, 1);
        roiPositions{i} = roi(scale, :);
    end
end

% Round outputs if requested
if(roundOut)
    roiPositions = cellfun(@round, roiPositions, "UniformOutput", false);
end

% Assign Outputs
if(nargout > 1)
    varargout{1, 1} = perimeters;
end

% Nested Functions
    function setDefaults()
        numroi = 0;
        conn = 8;
        fillHoles = true;
        npScale = 2;
        roundOut = false;
    end

    % points are sorted vertically, sort points based on dist from one
    % another
    function sorted = sortPoints(unsorted)
        % Initialize
        sorted = zeros(length(unsorted), 2);
        lenUnSort = length(unsorted);
        n = 1;

        % Pull first point from unsorted and store it in sorted
        sorted(n, :) = unsorted(n, :);
        unsorted(n, :) = [];

        while(n <= lenUnSort && ~isempty(unsorted))
            % Get the next point from sorted
            currPoint = sorted(n, :);
            % Calculate distances between unsorted and currPoint
            distFunc = @(x, y) sqrt((x - currPoint(1, 1)) ^ 2 + (y - currPoint(1, 2)) ^ 2);
            dists = arrayfun(distFunc, unsorted(:, 1), unsorted(:, 2));
            % Find the minimum distance and add it to sorted
            [~, minIdx] = min(dists);
            sorted(n+1, :) = unsorted(minIdx, :);
            % remove from unsorted and increment
            unsorted(minIdx, :) = [];
            n = n + 1;
        end
    end

end
