need    Hypervisor::IBM::POWER::HMC::REST::Atom;
need    Hypervisor::IBM::POWER::HMC::REST::Config;
need    Hypervisor::IBM::POWER::HMC::REST::Config::Analyze;
need    Hypervisor::IBM::POWER::HMC::REST::Config::Dump;
need    Hypervisor::IBM::POWER::HMC::REST::Config::Optimize;
use     Hypervisor::IBM::POWER::HMC::REST::Config::Traits;
need    Hypervisor::IBM::POWER::HMC::REST::ETL::XML;
need    Hypervisor::IBM::POWER::HMC::REST::ManagedSystems::ManagedSystem::PCM;
unit    class Hypervisor::IBM::POWER::HMC::REST::ManagedSystems::PCM:api<1>:auth<Mark Devine (mark@markdevine.com)>
            does Hypervisor::IBM::POWER::HMC::REST::Config::Analyze
            does Hypervisor::IBM::POWER::HMC::REST::Config::Dump
            does Hypervisor::IBM::POWER::HMC::REST::Config::Optimize
            does Hypervisor::IBM::POWER::HMC::REST::ETL::XML;

my      Bool                                                                                    $names-checked                              = False;
my      Bool                                                                                    $analyzed                                   = False;
my      Lock                                                                                    $lock                                       = Lock.new;
has     Bool                                                                                    $.initialized                               = False;
has     Hypervisor::IBM::POWER::HMC::REST::Config                                               $.config                                    is required;
has                                                                                             %.Managed-System-SystemName-to-Id           is required;
has     Hypervisor::IBM::POWER::HMC::REST::Atom                                                 $.atom                                      is conditional-initialization-attribute;
has     Str                                                                                     $.MaximumManagedSystemsForLongTermMonitor   is conditional-initialization-attribute;
has     Str                                                                                     $.MaximumManagedSystemsForComputeLTM        is conditional-initialization-attribute;
has     Str                                                                                     $.MaximumManagedSystemsForAggregation       is conditional-initialization-attribute;
has     Str                                                                                     $.MaximumManagedSystemsForShortTermMonitor  is conditional-initialization-attribute;
has     Str                                                                                     $.MaximumManagedSystemsForEnergyMonitor     is conditional-initialization-attribute;
has     Str                                                                                     $.AggregatedMetricsStorageDuration          is conditional-initialization-attribute;
has                                                                                             %.PCM-System                                is conditional-initialization-attribute;

method  xml-name-exceptions () { return set <Metadata ManagedSystemPcmPreference>; }

submethod TWEAK {
    self.config.diag.post:      self.^name ~ '::' ~ &?ROUTINE.name if %*ENV<HIPH_SUBMETHOD>;
    self.config.diag.post:      sprintf("%-20s %10s: %11s", self.^name.subst(/^.+'::'(.+)$/, {$0}), 'START', 't' ~ $*THREAD.id) if %*ENV<HIPH_THREAD_START>;
    my $proceed-with-analyze    = False;
    $lock.protect({
        if !$analyzed           { $proceed-with-analyze    = True; $analyzed      = True; }
    });
    self.init;
    self.analyze                if $proceed-with-analyze;
    self;
}

method init () {
    return self                                 if $!initialized;
    self.config.diag.post:                      self.^name ~ '::' ~ &?ROUTINE.name if %*ENV<HIPH_METHOD>;
    my $init-start                              = now;

    my $fetch-start                             = now;
    my $xml-path                                = self.config.session-manager.fetch('/rest/api/pcm/preferences');
    self.config.diag.post:                      sprintf("%-20s %10s: %11s", self.^name.subst(/^.+'::'(.+)$/, {$0}), 'FETCH', sprintf("%.3f", now - $fetch-start)) if %*ENV<HIPH_FETCH>;

    my $parse-start                             = now;
    self.etl-parse-path(:$xml-path);
    self.config.diag.post:                      sprintf("%-20s %10s: %11s", self.^name.subst(/^.+'::'(.+)$/, {$0}), 'PARSE', sprintf("%.3f", now - $parse-start)) if %*ENV<HIPH_PARSE>;

    my $xml-entry                               = self.etl-branch(:TAG<entry>,                                                          :$!xml);
    my $xml-content                             = self.etl-branch(:TAG<content>,                                                        :xml($xml-entry));
    my $xml-ManagementConsolePcmPreference      = self.etl-branch(:TAG<ManagementConsolePcmPreference:ManagementConsolePcmPreference>,  :xml($xml-content));

    my $proceed-with-name-check = False;
    $lock.protect({
        if !$names-checked                      { $proceed-with-name-check = True; $names-checked = True; }
    });
    self.etl-node-name-check(:xml($xml-ManagementConsolePcmPreference)) if $proceed-with-name-check;

    $!atom                                      = self.etl-atom(:xml(self.etl-branch(:TAG<Metadata>,            :xml($xml-ManagementConsolePcmPreference))))    if self.attribute-is-accessed(self.^name, 'atom');
    $!MaximumManagedSystemsForLongTermMonitor   = self.etl-text(:TAG<MaximumManagedSystemsForLongTermMonitor>,  :xml($xml-ManagementConsolePcmPreference))      if self.attribute-is-accessed(self.^name, 'MaximumManagedSystemsForLongTermMonitor');
    $!MaximumManagedSystemsForComputeLTM        = self.etl-text(:TAG<MaximumManagedSystemsForComputeLTM>,       :xml($xml-ManagementConsolePcmPreference))      if self.attribute-is-accessed(self.^name, 'MaximumManagedSystemsForComputeLTM');
    $!MaximumManagedSystemsForAggregation       = self.etl-text(:TAG<MaximumManagedSystemsForAggregation>,      :xml($xml-ManagementConsolePcmPreference))      if self.attribute-is-accessed(self.^name, 'MaximumManagedSystemsForAggregation');
    $!MaximumManagedSystemsForShortTermMonitor  = self.etl-text(:TAG<MaximumManagedSystemsForShortTermMonitor>, :xml($xml-ManagementConsolePcmPreference))      if self.attribute-is-accessed(self.^name, 'MaximumManagedSystemsForShortTermMonitor');
    $!MaximumManagedSystemsForEnergyMonitor     = self.etl-text(:TAG<MaximumManagedSystemsForEnergyMonitor>,    :xml($xml-ManagementConsolePcmPreference))      if self.attribute-is-accessed(self.^name, 'MaximumManagedSystemsForEnergyMonitor');
    $!AggregatedMetricsStorageDuration          = self.etl-text(:TAG<AggregatedMetricsStorageDuration>,         :xml($xml-ManagementConsolePcmPreference))      if self.attribute-is-accessed(self.^name, 'AggregatedMetricsStorageDuration');
    my @ManagedSystemPcmPreferences             = self.etl-branches(:TAG<ManagedSystemPcmPreference>, :xml($xml-ManagementConsolePcmPreference));
    die '# of known Managed Systems != # of retrieved ManagedSystemPcmPreferences' unless %.Managed-System-SystemName-to-Id.elems == @ManagedSystemPcmPreferences.elems;
    my @promises;
    for @ManagedSystemPcmPreferences -> $xml-ManagedSystemPcmPreference {
        my $SystemName                          = self.etl-text(:TAG<SystemName>, :xml($xml-ManagedSystemPcmPreference));
        die $SystemName ~ ' encountered in PCM without associated Managed System' unless %!Managed-System-SystemName-to-Id{$SystemName}:exists;
        @promises.push: start {
            Hypervisor::IBM::POWER::HMC::REST::ManagedSystems::ManagedSystem::PCM.new(:$!config, :xml($xml-ManagedSystemPcmPreference));
        }
    }
    unless await Promise.allof(@promises).then({ so all(@promises>>.result) }) {
        die &?ROUTINE.name ~ ': Not all promises were Kept!';
    }
    for @promises -> $promise {
        my $result                              = $promise.result;
        my $SystemName                          = $result.SystemName;
        %!PCM-System{$SystemName}               = $result;
    }
    die '# of known Managed Systems != # of instantiated PCM systems' unless %.Managed-System-SystemName-to-Id.elems == %!PCM-System.elems;
    $!xml                                       = Nil;
    $!initialized                               = True;
    self.config.diag.post:                      sprintf("%-20s %10s: %11s", self.^name.subst(/^.+'::'(.+)$/, {$0}), 'INITIALIZE', sprintf("%.3f", now - $init-start)) if %*ENV<HIPH_INIT>;
    self;
}

method AggregatedMetrics () {
#   *** Serial queries so that we don't overwhelm the HMC ***
    for %!Managed-System-SystemName-to-Id.keys -> $SystemName {
        $ = %!PCM-System{$SystemName}.AggregatedMetrics;
    }
}

method ProcessedMetrics () {
#   *** Serial queries so that we don't overwhelm the HMC ***
    for %!Managed-System-SystemName-to-Id.keys -> $SystemName {
        $ = %!PCM-System{$SystemName}.ProcessedMetrics;
    }
}

=finish
