function genStandardTestCases
    rng(20)
    xmax = 2320; % band width
    ymax = 1024; % band length
    bandSpeed = 28; % pixel per frame
    Length = 15;
    Width = 10;
    yPts = [0 900];
    y = 1:bandSpeed:ymax;

    % TestCase1
    trackPts1 = [500  300];
    trackPts2 = [600 900];
    trackPts3 = [1500 1100];

    trackPts = {trackPts1,trackPts2,trackPts3};
    tracks_start = [1,1,1];
    testPath = fullfile('test_case1.csv');
    labelPath = fullfile('test_case1_labels.csv');
    makeTest(trackPts,tracks_start,{[],[],[]},testPath,labelPath);
    %%
    % TestCase2
    trackPts1 = [200  200];
    trackPts2 = [300 1200];
    trackPts3 = [1000 1000];

    trackPts = {trackPts1,trackPts2,trackPts3};
    tracks_start = [1,1,10];
    testPath = fullfile('test_case2.csv');
    labelPath = fullfile('test_case2_labels.csv');
    makeTest(trackPts,tracks_start,{[],[],[]},testPath,labelPath);

    % TestCase3
    trackPts1 = [200  200];
    trackPts2 = [1000 1000];
    trackPts3 = [300 700];

    trackPts = {trackPts1,trackPts2,trackPts3};
    tracks_start = [1,1,1];
    testPath = fullfile('test_case3.csv');
    labelPath = fullfile('test_case3_labels.csv');
    makeTest(trackPts,tracks_start,{[],[],18:20},testPath,labelPath);

    % TestCase4
    trackPts1 = [400  400];
    trackPts2 = [800 800];
    trackPts3 = [200 1000];
    trackPts = {trackPts1,trackPts2,trackPts3};
    tracks_start = [1,1,1];
    testPath = fullfile('test_case4.csv');
    labelPath = fullfile('test_case4_labels.csv');
    makeTest(trackPts,tracks_start,{[],[],15:20},testPath,labelPath);

    % TestCase5
    trackPts1 = [600  600];
    trackPts2 = [800 800];
    trackPts3 = [200 1000];

    trackPts = {trackPts1,trackPts2,trackPts3};
    tracks_start = [1,1,10];
    testPath = fullfile('test_case5.csv');
    labelPath = fullfile('test_case5_labels.csv');
    makeTest(trackPts,tracks_start,{[],[],25:30},testPath,labelPath);
end