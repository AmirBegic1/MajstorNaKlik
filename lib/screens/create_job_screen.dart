import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/job_service.dart';
import '../services/category_service.dart';
import '../services/storage_service.dart';
import 'dart:io';

class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({super.key});

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _jobService = JobService();
  final _categoryService = CategoryService();
  final _storageService = StorageService();
  final _imagePicker = ImagePicker();

  // Form controllers
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _budgetController = TextEditingController();

  // Form state
  String _selectedCategory = '';
  String _selectedPriority = 'medium';
  DateTime? _scheduledDate;
  List<File> _selectedImages = [];
  bool _isLoading = false;
  bool _isUploadingImages = false;
  double _uploadProgress = 0.0;

  final List<String> _priorities = ['low', 'medium', 'high', 'urgent'];

  final Map<String, String> _priorityLabels = {
    'low': 'Nizak',
    'medium': 'Srednji',
    'high': 'Visok',
    'urgent': 'Hitno',
  };

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'high':
        return Colors.orange;
      case 'urgent':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _contactPhoneController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages = pickedFiles.map((file) => File(file.path)).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Greška pri odabiru slika: $e')));
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Izaberite željeni datum',
      cancelText: 'Otkaži',
      confirmText: 'Potvrdi',
    );

    if (picked != null) {
      setState(() {
        _scheduledDate = picked;
      });
    }
  }

  Future<void> _createJob() async {
    if (!_formKey.currentState!.validate() || _selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Molimo popunite sva obavezna polja')),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Morate biti prijavljeni')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final double? budget =
          _budgetController.text.isNotEmpty
              ? double.tryParse(_budgetController.text)
              : null;

      // Prvo kreiraj job bez slika da dobijem ID
      final String? jobId = await _jobService.createJob(
        title: _titleController.text.trim(),
        location: _locationController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        userId: currentUser.uid,
        contactPhone: _contactPhoneController.text.trim(),
        budget: budget,
        priority: _selectedPriority,
        images: [], // Prazan za sada
        scheduledDate: _scheduledDate,
      );

      if (jobId == null) {
        throw Exception('Nije moguće kreirati posao');
      }

      // Upload slike ako postoje
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        setState(() {
          _isUploadingImages = true;
          _uploadProgress = 0.0;
        });

        try {
          imageUrls = await _storageService.uploadJobImages(
            jobId,
            _selectedImages,
          );

          setState(() {
            _uploadProgress = 1.0;
          });

          // Ažuriraj job sa URL-ovima slika
          await _jobService.updateJobImages(jobId, imageUrls);
        } catch (e) {
          // Ako upload slika ne uspije, job je već kreiran ali bez slika
          print('Upozorenje: Slike nisu upload-ovane: $e');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Posao je kreiran, ali slike nisu spremljene: $e'),
              backgroundColor: Colors.orange,
            ),
          );
        } finally {
          if (mounted) {
            setState(() {
              _isUploadingImages = false;
            });
          }
        }
      }

      // Job je uspješno kreiran
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedImages.isNotEmpty &&
                    imageUrls.length == _selectedImages.length
                ? 'Posao je uspješno kreiran sa slikama!'
                : _selectedImages.isNotEmpty
                ? 'Posao je kreiran, ali neki problemi sa slikama'
                : 'Posao je uspješno kreiran!',
          ),
          backgroundColor:
              _selectedImages.isNotEmpty &&
                      imageUrls.length == _selectedImages.length
                  ? Colors.green
                  : _selectedImages.isNotEmpty
                  ? Colors.orange
                  : null,
        ),
      );
      Navigator.pop(context, true); // Vratiti true da signaliziramo uspjeh
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Greška: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Kreiraj novi posao'),
        elevation: 0,
        actions: [
          if (_isLoading || _isUploadingImages)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    if (_isUploadingImages) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${(_uploadProgress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.all(8),
              child: FilledButton.icon(
                onPressed: _createJob,
                icon: const Icon(Icons.publish, size: 18),
                label: const Text('OBJAVI'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Hero Section
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  children: [
                    Icon(
                      Icons.add_task_rounded,
                      size: 48,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Opišite svoj posao',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Detaljno opišite šta trebate i pronaći ćemo najbolje majstore',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Main Form Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Basic Information Card
                    Card(
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Osnovne informacije',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Naslov posla
                            TextFormField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                labelText: 'Naslov posla *',
                                hintText: 'npr. Popravka slavine u kuhinji',
                                prefixIcon: Icon(
                                  Icons.work_outline,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Naslov je obavezan';
                                }
                                if (value.trim().length < 5) {
                                  return 'Naslov mora imati najmanje 5 karaktera';
                                }
                                return null;
                              },
                              textCapitalization: TextCapitalization.sentences,
                            ),

                            const SizedBox(height: 20),

                            // Lokacija
                            TextFormField(
                              controller: _locationController,
                              decoration: InputDecoration(
                                labelText: 'Lokacija *',
                                hintText: 'npr. Sarajevo, Centar',
                                prefixIcon: Icon(
                                  Icons.location_on_outlined,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Lokacija je obavezna';
                                }
                                return null;
                              },
                              textCapitalization: TextCapitalization.words,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Category & Description Card
                    Card(
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.description_outlined,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Opis i kategorija',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Kategorija
                            StreamBuilder<List<Category>>(
                              stream: _categoryService.getCategories(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  final categories = snapshot.data!;
                                  return DropdownButtonFormField<String>(
                                    value:
                                        _selectedCategory.isNotEmpty
                                            ? _selectedCategory
                                            : null,
                                    decoration: InputDecoration(
                                      labelText: 'Kategorija *',
                                      prefixIcon: Icon(
                                        Icons.category_outlined,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                      ),
                                    ),
                                    items:
                                        categories.map((category) {
                                          return DropdownMenuItem<String>(
                                            value: category.id,
                                            child: Text(category.name),
                                          );
                                        }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedCategory = value ?? '';
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Kategorija je obavezna';
                                      }
                                      return null;
                                    },
                                  );
                                }
                                return DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    labelText: 'Kategorija * (učitava se...)',
                                    prefixIcon: Icon(
                                      Icons.category_outlined,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  items: const [],
                                  onChanged: null,
                                );
                              },
                            ),

                            const SizedBox(height: 20),

                            // Opis posla
                            TextFormField(
                              controller: _descriptionController,
                              decoration: InputDecoration(
                                labelText: 'Detaljan opis posla *',
                                hintText: 'Opišite što trebate da se uradi...',
                                prefixIcon: Icon(
                                  Icons.edit_outlined,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                alignLabelWithHint: true,
                              ),
                              maxLines: 4,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Opis je obavezan';
                                }
                                if (value.trim().length < 20) {
                                  return 'Opis mora imati najmanje 20 karaktera';
                                }
                                return null;
                              },
                              textCapitalization: TextCapitalization.sentences,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Contact & Budget Card
                    Card(
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_outlined,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Kontakt i budžet',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Kontakt telefon
                            TextFormField(
                              controller: _contactPhoneController,
                              decoration: InputDecoration(
                                labelText: 'Kontakt telefon *',
                                hintText: '+387 XX XXX XXX',
                                prefixIcon: Icon(
                                  Icons.phone_outlined,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Kontakt telefon je obavezan';
                                }
                                if (value.trim().length < 8) {
                                  return 'Unesite valjan broj telefona';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            // Budžet
                            TextFormField(
                              controller: _budgetController,
                              decoration: InputDecoration(
                                labelText: 'Predloženi budžet (KM)',
                                hintText: 'Koliko ste spremni platiti?',
                                prefixIcon: Icon(
                                  Icons.attach_money_outlined,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final budget = double.tryParse(value);
                                  if (budget == null || budget <= 0) {
                                    return 'Unesite valjan iznos';
                                  }
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Priority & Schedule Card
                    Card(
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule_outlined,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Prioritet i termin',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Prioritet
                            DropdownButtonFormField<String>(
                              value: _selectedPriority,
                              decoration: InputDecoration(
                                labelText: 'Prioritet',
                                prefixIcon: Icon(
                                  Icons.priority_high_outlined,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              items:
                                  _priorities.map((priority) {
                                    return DropdownMenuItem<String>(
                                      value: priority,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: _getPriorityColor(
                                                priority,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(_priorityLabels[priority]!),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedPriority = value ?? 'medium';
                                });
                              },
                            ),

                            const SizedBox(height: 20),

                            // Željeni datum
                            Card(
                              elevation: 0,
                              color: Theme.of(
                                context,
                              ).colorScheme.surface.withOpacity(0.5),
                              child: ListTile(
                                leading: Icon(
                                  Icons.calendar_today_outlined,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                title: const Text('Željeni datum završetka'),
                                subtitle:
                                    _scheduledDate != null
                                        ? Text(
                                          '${_scheduledDate!.day}.${_scheduledDate!.month}.${_scheduledDate!.year}.',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        )
                                        : const Text('Nije specificiran'),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                onTap: _selectDate,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Images Card
                    Card(
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.photo_library_outlined,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Dodaj slike',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                FilledButton.tonalIcon(
                                  onPressed: _pickImages,
                                  icon: const Icon(Icons.add_a_photo, size: 18),
                                  label: const Text('Dodaj slike'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_selectedImages.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Odabrano: ${_selectedImages.length} ${_selectedImages.length == 1 ? 'slika' : 'slika'}',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 100,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _selectedImages.length,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      margin: const EdgeInsets.only(right: 12),
                                      child: Stack(
                                        children: [
                                          Container(
                                            width: 100,
                                            height: 100,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              image: DecorationImage(
                                                image: FileImage(
                                                  _selectedImages[index],
                                                ),
                                                fit: BoxFit.cover,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.1),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Positioned(
                                            top: 6,
                                            right: 6,
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _selectedImages.removeAt(
                                                    index,
                                                  );
                                                });
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  size: 16,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.3),
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 48,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Dodajte slike vašeg problema',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Slike pomažu majstorima da bolje razumiju posao',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Objavi button (backup za male ekrane)
                    Container(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            (_isLoading || _isUploadingImages)
                                ? null
                                : _createJob,
                        icon:
                            (_isLoading || _isUploadingImages)
                                ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.publish),
                        label: Text(
                          _isLoading
                              ? 'Kreiram posao...'
                              : _isUploadingImages
                              ? 'Upload slika ${(_uploadProgress * 100).toInt()}%'
                              : 'Objavi posao',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
