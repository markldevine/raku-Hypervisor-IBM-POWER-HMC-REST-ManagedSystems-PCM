need    Hypervisor::IBM::POWER::HMC::REST::Atom;
need    Hypervisor::IBM::POWER::HMC::REST::Config;
need    Hypervisor::IBM::POWER::HMC::REST::Config::Analyze;
need    Hypervisor::IBM::POWER::HMC::REST::Config::Dump;
need    Hypervisor::IBM::POWER::HMC::REST::Config::Optimize;
use     Hypervisor::IBM::POWER::HMC::REST::Config::Traits;
need    Hypervisor::IBM::POWER::HMC::REST::ETL::XML;
need    Hypervisor::IBM::POWER::HMC::REST::ManagedSystems::ManagedSystem::PCM;
need    Hypervisor::IBM::POWER::HMC::REST::ManagedSystems::ManagedSystem::PCM::MachineTypeModelSerialNumber;
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
has                                                                                                         @.Managed-SystemNames           is required;
has     Hypervisor::IBM::POWER::HMC::REST::Atom                                                             $.atom                          is conditional-initialization-attribute;
has     Str                                                                                                 $.SystemName                    is conditional-initialization-attribute;
has     Hypervisor::IBM::POWER::HMC::REST::ManagedSystems::ManagedSystem::PCM::MachineTypeModelSerialNumber $.MachineTypeModelSerialNumber  is conditional-initialization-attribute;
has     Str                                                                                                 $.EnergyMonitoringCapable       is conditional-initialization-attribute;
has     Str                                                                                                 $.LongTermMonitorEnabled        is conditional-initialization-attribute;
has     Str                                                                                                 $.AggregationEnabled            is conditional-initialization-attribute;
has     Str                                                                                                 $.ShortTermMonitorEnabled       is conditional-initialization-attribute;
has     Str                                                                                                 $.ComputeLTMEnabled             is conditional-initialization-attribute;
has     Str                                                                                                 $.EnergyMonitorEnabled          is conditional-initialization-attribute;
has     URI                                                                                                 $.AssociatedManagedSystem       is conditional-initialization-attribute;

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
    my $init-start              = now;
    my $proceed-with-name-check = False;
    $lock.protect({
        if !$names-checked      { $proceed-with-name-check = True; $names-checked = True; }
    });
    self.etl-node-name-check    if $proceed-with-name-check;
    $!atom                      = self.etl-atom(:xml(self.etl-branch(:TAG<Metadata>,                :$!xml)))   if self.attribute-is-accessed(self.^name, 'atom');
    $!SystemName                = self.etl-text(:TAG<SystemName>,                                   :$!xml))    if self.attribute-is-accessed(self.^name, 'SystemName');
    if self.attribute-is-accessed(self.^name, 'MachineTypeModelSerialNumber') {
        my $xml-MachineTypeModelSerialNumber = self.etl-branch(:TAG<MachineTypeModelSerialNumber>,  :$!xml);
        $!MachineTypeModelSerialNumber       = Hypervisor::IBM::POWER::HMC::REST::ManagedSystems::ManagedSystem::PCM::MachineTypeModelSerialNumber.new(:$!config, :xml($xml-MachineTypeModelSerialNumber));
    }
    $!EnergyMonitoringCapable   = self.etl-text(:TAG<EnergyMonitoringCapable>,                      :$!xml))    if self.attribute-is-accessed(self.^name, 'EnergyMonitoringCapable');
    $!LongTermMonitorEnabled    = self.etl-text(:TAG<LongTermMonitorEnabled>,                       :$!xml))    if self.attribute-is-accessed(self.^name, 'LongTermMonitorEnabled');
    $!AggregationEnabled        = self.etl-text(:TAG<AggregationEnabled>,                           :$!xml))    if self.attribute-is-accessed(self.^name, 'AggregationEnabled');
    $!ShortTermMonitorEnabled   = self.etl-text(:TAG<ShortTermMonitorEnabled>,                      :$!xml))    if self.attribute-is-accessed(self.^name, 'ShortTermMonitorEnabled');
    $!ComputeLTMEnabled         = self.etl-text(:TAG<ComputeLTMEnabled>,                            :$!xml))    if self.attribute-is-accessed(self.^name, 'ComputeLTMEnabled');
    $!EnergyMonitorEnabled      = self.etl-text(:TAG<EnergyMonitorEnabled>,                         :$!xml))    if self.attribute-is-accessed(self.^name, 'EnergyMonitorEnabled');
    $!AssociatedManagedSystem   = self.etl-href(:xml(self.etl-branch(:TAG<AssociatedManagedSystem>, :$!xml)))   if self.attribute-is-accessed(self.^name, 'AssociatedManagedSystem');
    $!xml                       = Nil;
    $!initialized               = True;
    self.config.diag.post:      sprintf("%-20s %10s: %11s", self.^name.subst(/^.+'::'(.+)$/, {$0}), 'INITIALIZE', sprintf("%.3f", now - $init-start)) if %*ENV<HIPH_INIT>;
    self;
}

=finish
