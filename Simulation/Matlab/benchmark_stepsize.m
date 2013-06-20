function [cpu,gpu] = benchmark_stepsize()
    data = csvread('/Users/johannes/Dropbox/Bachelor/TrackingPositrons/Simulation/Data/benchmark_stepsize');
    data(:,3) = data(:,3) / max(data(:,3));
    for i=1:length(data)
        data(i,2) = 1/data(i,2);
    end
    cpu = [];
    gpu = [];
    comparison = [];
    for i=1:length(data)
        if data(i,1) == 0
            cpu = [cpu;data(i,2:3)];
        else
            gpu = [gpu;data(i,2:3)];
        end
    end
    for i=1:length(cpu)
       comparison(i,:) = [cpu(i,1),gpu(i,2)/cpu(i,2)];
    end
    hold off
    plot(cpu(:,1),cpu(:,2),'-ob','LineWidth',2);
    hold on
    plot(gpu(:,1),gpu(:,2),'-o','Color',[0 0.75 0],'LineWidth',2);
    plot(comparison(:,1),comparison(:,2),'--r','LineWidth',2);
    title('Energy loss for 2048 muons in various materials','FontSize',20);
    xlabel('Steps per centimeter [1/cm]','FontSize',20);
    ylabel('Normalized runtime [1/max]','FontSize',20);
    l1=legend('CPU','GPU','GPU time / CPU time','Location','NorthWest');
    set(l1,'FontSize',19);
    set(gca,'FontSize',20,'XScale','log');
    axis([min(data(:,2)) max(data(:,2)) 0 1]);
end