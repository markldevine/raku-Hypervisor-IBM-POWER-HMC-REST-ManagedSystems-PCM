need    Hypervisor::IBM::POWER::HMC::REST::Atom;
need    Hypervisor::IBM::POWER::HMC::REST::Config;
need    Hypervisor::IBM::POWER::HMC::REST::Config::Analyze;
need    Hypervisor::IBM::POWER::HMC::REST::Config::Dump;
need    Hypervisor::IBM::POWER::HMC::REST::Config::Optimize;
use     Hypervisor::IBM::POWER::HMC::REST::Config::Traits;
need    Hypervisor::IBM::POWER::HMC::REST::ETL::XML;
#need    Hypervisor::IBM::POWER::HMC::REST::ManagedSystems::ManagedSystem::PCM::AggregatedMetrics::ManagedSystem;
#need    Hypervisor::IBM::POWER::HMC::REST::ManagedSystems::ManagedSystem::PCM::AggregatedMetrics::LogicalPartition;
unit    class Hypervisor::IBM::POWER::HMC::REST::ManagedSystems::ManagedSystem::PCM::AggregatedMetrics:api<1>:auth<Mark Devine (mark@markdevine.com)>
            does Hypervisor::IBM::POWER::HMC::REST::Config::Analyze
            does Hypervisor::IBM::POWER::HMC::REST::Config::Dump
            does Hypervisor::IBM::POWER::HMC::REST::Config::Optimize
            does Hypervisor::IBM::POWER::HMC::REST::ETL::XML;

my      Bool                                        $names-checked  = False;
my      Bool                                        $analyzed       = False;
my      Lock                                        $lock           = Lock.new;
has     Bool                                        $.initialized   = False;
has     Hypervisor::IBM::POWER::HMC::REST::Config   $.config        is required;




#has     Str                                         $.MachineType   is conditional-initialization-attribute;
#has     Str                                         $.Model         is conditional-initialization-attribute;
#has     Str                                         $.SerialNumber  is conditional-initialization-attribute;



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



#   $!MachineType               = self.etl-text(:TAG<MachineType>,  :$!xml) if self.attribute-is-accessed(self.^name, 'MachineType');
#   $!Model                     = self.etl-text(:TAG<Model>,        :$!xml) if self.attribute-is-accessed(self.^name, 'Model');
#   $!SerialNumber              = self.etl-text(:TAG<SerialNumber>, :$!xml) if self.attribute-is-accessed(self.^name, 'SerialNumber');

    $!xml                       = Nil;
    $!initialized               = True;
    self;
}

=finish
