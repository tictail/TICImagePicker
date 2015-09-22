Pod::Spec.new do |spec|
  spec.name = 'TICImagePicker'
  spec.version = '1.2'
  spec.summary = 'An image picker that displays the camera along with assets. Uses Photos framework (requires iOS 8).'  
  spec.license = 'MIT' 
  spec.homepage = 'https://tictail.com'
  spec.authors = { 'Martin Hwasser' => 'martin.hwasser@gmail.com' }
  spec.source = { :git => 'https://github.com/tictail/TICImagePicker.git', :tag => spec.version.to_s }
  spec.frameworks = 'Photos'
  spec.platform = :ios, '8.0'
  spec.source_files = 'TICImagePicker/*.{h,m}'
  spec.resource_bundles = { 'TICImagePickerResources' => "TICImagePicker/Resources/*" }
  spec.requires_arc = true
end

