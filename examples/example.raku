#!/usr/bin/env raku

use     Hypervisor::IBM::POWER::HMC::REST::Config::Options;
need    Hypervisor::IBM::POWER::HMC::REST::HMC;

sub USAGE { Hypervisor::IBM::POWER::HMC::REST::Config::Options::usage(); }
unit sub MAIN (*%options);

my $mc = Hypervisor::IBM::POWER::HMC::REST::HMC.new(:options(Hypervisor::IBM::POWER::HMC::REST::Config::Options.new(|Map.new(%options.kv))));
#$mc.ManagementConsole.init;
$mc.ManagedSystems.init;
#$mc.ManagedSystems.Initialize-Logical-Partitions;
#$mc.ManagedSystems.Initialize-Virtual-IO-Servers;
$mc.ManagedSystems.Initialize-PCM;
#$mc.ManagedSystems.PCM.AggregatedMetrics;
#$mc.ManagedSystems.PCM.ProcessedMetrics;
$mc.ManagedSystems.PCM.RawMetrics-LongTermMonitor;

#$mc.ManagedSystems.PCM.dump;
#$mc.dump;

=finish
