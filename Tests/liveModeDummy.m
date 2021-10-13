function liveModeDummy(path, numberOfEmptyEnd)
% @author Florian Pfaff
% @date 2014-2021
arguments
    path char{mustBeNonzeroLengthText}
    numberOfEmptyEnd (1, 1) double = 0
end
fileInfos = dir(fullfile(path, 'Partikelpositionen*.txt'));
for i = 1:numel(fileInfos)
    pause(1) % Should be locked currently
    copyfile(fullfile(path, sprintf('Partikelpositionen_%02d.txt', i)), 'Partikelpositionen.txt', 'f');
    file = fopen('Partikelpositionen_blockiert.txt', 'w');
    fprintf(file, num2str(i*0.005));
    fclose(file);
end
if numberOfEmptyEnd > 0
    pause(1);
    i = i + 1;
    tmpTab = readtable('Partikelpositionen.txt');
    tmpTab(:, :) = [];
    writetable(tmpTab, 'Partikelpositionen.txt', Delimiter = ';')
    file = fopen('Partikelpositionen_blockiert.txt', 'w');
    fprintf(file, num2str(i*0.005));
    fclose(file);
end
for j = 1:numberOfEmptyEnd - 1
    pause(1);
    i = i + 1;
    file = fopen('Partikelpositionen_blockiert.txt', 'w');
    fprintf(file, num2str(i*0.005));
    fclose(file);
end
pause(1)
% End test
file = fopen('Partikelpositionen_blockiert.txt', 'w');
fprintf(file, 'end');
fclose(file);
end