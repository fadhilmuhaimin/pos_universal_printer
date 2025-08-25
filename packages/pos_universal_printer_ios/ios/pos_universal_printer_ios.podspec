Pod::Spec.new do |s|
  s.name             = 'pos_universal_printer_ios'
  s.version          = '0.1.0'
  s.summary          = 'iOS implementation of pos_universal_printer'
  s.description      = <<-DESC
    PosUniversalPrinter iOS implementation. Provides a TCP client for
    sending ESC/POS, TSPL and CPCL commands to network printers.
    Bluetooth Serial Port Profile is not supported on iOS【229364017025404†L45-L58】.
  DESC
  s.homepage         = 'https://example.com/pos_universal_printer_ios'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'pos_universal' => 'example@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '12.0'
end