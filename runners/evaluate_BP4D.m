addpath('../data extraction/');

find_BP4D;

aus_BP4D = [1, 2, 4, 6, 7, 10, 12, 14, 15, 17, 23];

root = 'out_bp4d_static/';

[ labels_gt, valid_ids, vid_ids, filenames] = extract_BP4D_labels(BP4D_dir, devel_recs, aus_BP4D);
labels_gt = cat(1, labels_gt{:});
labels_pred = [];
for i=1:numel(filenames)
    lbl = dlmread([root, filenames{i}, '.au.txt'], ' ');
    labels_pred = cat(1, labels_pred, lbl(:,1:end-1));
end

labels_pred(labels_pred==5) = 1;

tp = sum(labels_gt == 1 & labels_pred == 1);
fp = sum(labels_gt == 0 & labels_pred == 1);
fn = sum(labels_gt == 1 & labels_pred == 0);
tn = sum(labels_gt == 0 & labels_pred == 0);

precision = tp./(tp+fp);
recall = tp./(tp+fn);

f1 = 2 * precision .* recall ./ (precision + recall);

for a = 1:numel(aus_BP4D)
       
    fprintf('AU%d, Precision - %.3f, Recall - %.3f, F1 - %.3f\n', aus_BP4D(a), precision(a), recall(a), f1(a));
    
end