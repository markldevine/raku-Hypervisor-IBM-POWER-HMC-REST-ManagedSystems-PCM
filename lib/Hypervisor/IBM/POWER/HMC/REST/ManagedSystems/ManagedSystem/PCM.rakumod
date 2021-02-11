need    Hypervisor::IBM::POWER::HMC::REST::Atom;
need    Hypervisor::IBM::POWER::HMC::REST::Config;
need    Hypervisor::IBM::POWER::HMC::REST::Config::Analyze;
need    Hypervisor::IBM::POWER::HMC::REST::Config::Dump;
need    Hypervisor::IBM::POWER::HMC::REST::Config::Optimize;
use     Hypervisor::IBM::POWER::HMC::REST::Config::Traits;
need    Hypervisor::IBM::POWER::HMC::REST::ETL::XML;
need    Hypervisor::IBM::POWER::HMC::REST::ManagedSystems::ManagedSystem::PCM::MachineTypeModelSerialNumber;
use     URI;
unit    class Hypervisor::IBM::POWER::HMC::REST::ManagedSystems::ManagedSystem::PCM:api<1>:auth<Mark Devine (mark@markdevine.com)>
            does Hypervisor::IBM::POWER::HMC::REST::Config::Analyze
            does Hypervisor::IBM::POWER::HMC::REST::Config::Dump
            does Hypervisor::IBM::POWER::HMC::REST::Config::Optimize
            does Hypervisor::IBM::POWER::HMC::REST::ETL::XML;

my      Bool                                                                                                $names-checked                  = False;
my      Bool                                                                                                $analyzed                       = False;
my      Lock                                                                                                $lock                           = Lock.new;
has     Bool                                                                                                $.initialized                   = False;
has     Hypervisor::IBM::POWER::HMC::REST::Config                                                           $.config                        is required;
has     Hypervisor::IBM::POWER::HMC::REST::Atom                                                             $.atom                          is conditional-initialization-attribute;
has     Str                                                                                                 $.SystemName                    is conditional-initialization-attribute;
has     Hypervisor::IBM::POWER::HMC::REST::ManagedSystems::ManagedSystem::PCM::MachineTypeModelSerialNumber $.MachineTypeModelSerialNumber  is conditional-initialization-attribute;
has     Str                                                                                                 $.EnergyMonitoringCapable       is conditional-initialization-attribute;
has     Str                                                                                                 $.LongTermMonitorEnabled        is conditional-initialization-attribute;
has     Str                                                                                                 $.AggregationEnabled            is conditional-initialization-attribute;
has     Str                                                                                                 $.ShortTermMonitorEnabled       is conditional-initialization-attribute;
has     Str                                                                                                 $.ComputeLTMEnabled             is conditional-initialization-attribute;
has     Str                                                                                                 $.EnergyMonitorEnabled          is conditional-initialization-attribute;
has     URI                                                                                                 $.AssociatedManagedSystem;
has     Str                                                                                                 $.id;

method  xml-name-exceptions () { return set <Metadata>; }

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
    return self                 if $!initialized;
    self.config.diag.post:      self.^name ~ '::' ~ &?ROUTINE.name if %*ENV<HIPH_METHOD>;
    my $proceed-with-name-check = False;
    $lock.protect({
        if !$names-checked      { $proceed-with-name-check = True; $names-checked = True; }
    });
    self.etl-node-name-check    if $proceed-with-name-check;
    $!atom                      = self.etl-atom(:xml(self.etl-branch(:TAG<Metadata>,                :$!xml)))   if self.attribute-is-accessed(self.^name, 'atom');
    $!SystemName                = self.etl-text(:TAG<SystemName>,                                   :$!xml)     if self.attribute-is-accessed(self.^name, 'SystemName');
    if self.attribute-is-accessed(self.^name, 'MachineTypeModelSerialNumber') {
        my $xml-MachineTypeModelSerialNumber = self.etl-branch(:TAG<MachineTypeModelSerialNumber>,  :$!xml);
        $!MachineTypeModelSerialNumber       = Hypervisor::IBM::POWER::HMC::REST::ManagedSystems::ManagedSystem::PCM::MachineTypeModelSerialNumber.new(:$!config, :xml($xml-MachineTypeModelSerialNumber));
    }
    $!EnergyMonitoringCapable   = self.etl-text(:TAG<EnergyMonitoringCapable>,                      :$!xml)     if self.attribute-is-accessed(self.^name, 'EnergyMonitoringCapable');
    $!LongTermMonitorEnabled    = self.etl-text(:TAG<LongTermMonitorEnabled>,                       :$!xml)     if self.attribute-is-accessed(self.^name, 'LongTermMonitorEnabled');
    $!AggregationEnabled        = self.etl-text(:TAG<AggregationEnabled>,                           :$!xml)     if self.attribute-is-accessed(self.^name, 'AggregationEnabled');
    $!ShortTermMonitorEnabled   = self.etl-text(:TAG<ShortTermMonitorEnabled>,                      :$!xml)     if self.attribute-is-accessed(self.^name, 'ShortTermMonitorEnabled');
    $!ComputeLTMEnabled         = self.etl-text(:TAG<ComputeLTMEnabled>,                            :$!xml)     if self.attribute-is-accessed(self.^name, 'ComputeLTMEnabled');
    $!EnergyMonitorEnabled      = self.etl-text(:TAG<EnergyMonitorEnabled>,                         :$!xml)     if self.attribute-is-accessed(self.^name, 'EnergyMonitorEnabled');
    $!AssociatedManagedSystem   = self.etl-href(:xml(self.etl-branch(:TAG<AssociatedManagedSystem>, :$!xml)));
    $!id                        = self.AssociatedManagedSystem.path.Str.split(/\//).tail;
    $!xml                       = Nil;
    $!initialized               = True;
    self;
}

method fetch () {
    my $fetch-start                             = now;
    my $xml-path                                = self.config.session-manager.fetch('/rest/api/pcm/ManagedSystem/' ~ $!id ~ '/AggregatedMetrics');
    self.config.diag.post:                      sprintf("%-20s %10s: %11s", self.^name.subst(/^.+'::'(.+)$/, {$0}), 'FETCH', sprintf("%.3f", now - $fetch-start)) if %*ENV<HIPH_FETCH>;

    my $parse-start                             = now;
    self.etl-parse-path(:$xml-path);
    self.config.diag.post:                      sprintf("%-20s %10s: %11s", self.^name.subst(/^.+'::'(.+)$/, {$0}), 'PARSE', sprintf("%.3f", now - $parse-start)) if %*ENV<HIPH_PARSE>;

#   my $xml-entry                               = self.etl-branch(:TAG<entry>,                                                          :$!xml);
#   my $xml-content                             = self.etl-branch(:TAG<content>,                                                        :xml($xml-entry));
#   my $xml-ManagementConsolePcmPreference      = self.etl-branch(:TAG<ManagementConsolePcmPreference:ManagementConsolePcmPreference>,  :xml($xml-content));

}

=finish
