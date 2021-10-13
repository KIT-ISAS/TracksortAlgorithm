function grid = makeAllignmentGrid(first_pos,n,horiz_align,verti_align)
%MAKEALLIGNMENTGRID Summary of this function goes here
%   Detailed explanation goes here

grid1plane = repmat((0:n-1)*horiz_align+first_pos(1),1,1,n);
grid2plane = permute(repmat((0:n-1)*verti_align+first_pos(2),1,1,n),[1,3,2]);
grid = [grid1plane;grid2plane];
if numel(first_pos) == 4
     grid = [grid;repmat(first_pos(3:4)',1,n,n)];
end

end




% h = [horiz_align 0];
% v = [0 verti_align];
% gridfront = repmat((repmat([first_pos(1) 0],5,1)+repmat(0:n-1,2,1)'*diag(h))',1,1,n);
% griddepth = permute(repmat((repmat([0 first_pos(2)],5,1)+repmat(0:n-1,2,1)'*diag(v))',1,1,n),[1,3,2]);
% grid= gridfront+griddepth;
% if numel(firs_pos) == 4
%     grid = cat(1,grid,repmat(first_pos(3:4)',1,n,n));
% end