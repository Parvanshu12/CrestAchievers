import '../models/course_model.dart';

class MockData {
  static final List<Course> sampleCourses = [
    Course(
      id: 'jee_achievers_2026',
      title: 'JEE Main & Advanced Complete prep',
      tagline: 'Master Physics, Chemistry, and Mathematics for India\'s toughest engineering exam.',
      price: 14999.00,
      coverImageUrl: 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?auto=format&fit=crop&q=80&w=600',
      subjects: [
        Subject(
          name: 'Physics',
          chapters: [
            Chapter(
              id: 'jee_phy_ch1',
              title: 'Kinematics & Motion',
              lectures: [
                Lecture(
                  title: 'Lecture 1: Rest, Motion, & 1D Parameters',
                  videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
                  duration: '22 mins',
                ),
                Lecture(
                  title: 'Lecture 2: Equations of Motion & Graphs',
                  videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
                  duration: '35 mins',
                ),
                Lecture(
                  title: 'Lecture 3: Projectile Motion & Vector Resolution',
                  videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
                  duration: '15 mins',
                ),
              ],
              notes: [
                Note(
                  title: 'Kinematics Revision Formulas & Core Concepts',
                  pdfUrl: 'https://pdfobject.com/pdf/sample.pdf',
                ),
                Note(
                  title: 'Daily Practice Problem (DPP) - Kinematics',
                  pdfUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
                ),
              ],
            ),
            Chapter(
              id: 'jee_phy_ch2',
              title: 'Newton\'s Laws of Motion',
              lectures: [
                Lecture(
                  title: 'Lecture 1: Inertia, Force, & First Law',
                  videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
                  duration: '14 mins',
                ),
                Lecture(
                  title: 'Lecture 2: Free Body Diagrams & Friction',
                  videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
                  duration: '15 mins',
                ),
              ],
              notes: [
                Note(
                  title: 'Laws of Motion Core DPP with Solutions',
                  pdfUrl: 'https://pdfobject.com/pdf/sample.pdf',
                ),
              ],
            ),
          ],
        ),
        Subject(
          name: 'Chemistry',
          chapters: [
            Chapter(
              id: 'jee_chem_ch1',
              title: 'Some Basic Concepts of Chemistry (Mole Concept)',
              lectures: [
                Lecture(
                  title: 'Lecture 1: Atomic Mass, Molecular Mass & Moles',
                  videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4',
                  duration: '15 mins',
                ),
                Lecture(
                  title: 'Lecture 2: Stoichiometry & Limiting Reagent',
                  videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4',
                  duration: '15 mins',
                ),
              ],
              notes: [
                Note(
                  title: 'Mole Concept Revision Sheet',
                  pdfUrl: 'https://pdfobject.com/pdf/sample.pdf',
                ),
              ],
            ),
          ],
        ),
        Subject(
          name: 'Mathematics',
          chapters: [
            Chapter(
              id: 'jee_math_ch1',
              title: 'Quadratic Equations',
              lectures: [
                Lecture(
                  title: 'Lecture 1: Roots, Discriminant, & Nature of Roots',
                  videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4',
                  duration: '9 mins',
                ),
                Lecture(
                  title: 'Lecture 2: Location of Roots & Graphs',
                  videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
                  duration: '40 mins',
                ),
              ],
              notes: [
                Note(
                  title: 'Quadratic Equations Complete Formula Bank',
                  pdfUrl: 'https://pdfobject.com/pdf/sample.pdf',
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    Course(
      id: 'neet_elite_2026',
      title: 'NEET Ultimate Champion Preparation',
      tagline: 'Crack NEET with targeted classes in Physics, Chemistry, and Biological Sciences.',
      price: 12999.00,
      coverImageUrl: 'https://images.unsplash.com/photo-1576091160550-2173dba999ef?auto=format&fit=crop&q=80&w=600',
      subjects: [
        Subject(
          name: 'Biology',
          chapters: [
            Chapter(
              id: 'neet_bio_ch1',
              title: 'Cell: The Unit of Life',
              lectures: [
                Lecture(
                  title: 'Lecture 1: Cell Theory & Prokaryotic Cells',
                  videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
                  duration: '22 mins',
                ),
                Lecture(
                  title: 'Lecture 2: Eukaryotic Cell Organelles',
                  videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
                  duration: '35 mins',
                ),
              ],
              notes: [
                Note(
                  title: 'Cell Organelles Structure & Functions NCERT summary',
                  pdfUrl: 'https://pdfobject.com/pdf/sample.pdf',
                ),
              ],
            ),
          ],
        ),
        Subject(
          name: 'Physics',
          chapters: [
            Chapter(
              id: 'neet_phy_ch1',
              title: 'Physical World & Units of Measurement',
              lectures: [
                Lecture(
                  title: 'Lecture 1: Dimensions & Dimensional Analysis',
                  videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
                  duration: '15 mins',
                ),
              ],
              notes: [
                Note(
                  title: 'Dimensional Analysis & Errors Notes',
                  pdfUrl: 'https://pdfobject.com/pdf/sample.pdf',
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    Course(
      id: 'class_12_pcm_2026',
      title: 'Class 12th Board PCM Excellence',
      tagline: 'Score 95%+ in Class 12 Boards. Full syllabus PCM coverage with descriptive answering keys.',
      price: 5999.00,
      coverImageUrl: 'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?auto=format&fit=crop&q=80&w=600',
      subjects: [
        Subject(
          name: 'Physics',
          chapters: [
            Chapter(
              id: 'c12_phy_ch1',
              title: 'Electrostatics & Electric Fields',
              lectures: [
                Lecture(
                  title: 'Lecture 1: Coulomb\'s Law & Superposition',
                  videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
                  duration: '22 mins',
                ),
              ],
              notes: [
                Note(
                  title: 'Electrostatics Board Exam Sample Questions',
                  pdfUrl: 'https://pdfobject.com/pdf/sample.pdf',
                ),
              ],
            ),
          ],
        ),
        Subject(
          name: 'Chemistry',
          chapters: [
            Chapter(
              id: 'c12_chem_ch1',
              title: 'Solutions & Colligative Properties',
              lectures: [
                Lecture(
                  title: 'Lecture 1: Concentration Terms & Raoult\'s Law',
                  videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
                  duration: '35 mins',
                ),
              ],
              notes: [
                Note(
                  title: 'Solutions Formula List',
                  pdfUrl: 'https://pdfobject.com/pdf/sample.pdf',
                ),
              ],
            ),
          ],
        ),
        Subject(
          name: 'Mathematics',
          chapters: [
            Chapter(
              id: 'c12_math_ch1',
              title: 'Matrices & Determinants',
              lectures: [
                Lecture(
                  title: 'Lecture 1: Types of Matrices & Algebra',
                  videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
                  duration: '15 mins',
                ),
              ],
              notes: [
                Note(
                  title: 'Matrix Properties & Shortcuts Notes',
                  pdfUrl: 'https://pdfobject.com/pdf/sample.pdf',
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    Course(
      id: 'class_11_pcm_2026',
      title: 'Class 11th Foundation PCM Course',
      tagline: 'Build an rock-solid base in Physics, Chemistry, and Math. Transition from school to boards smoothly.',
      price: 4999.00,
      coverImageUrl: 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&q=80&w=600',
      subjects: [
        Subject(
          name: 'Physics',
          chapters: [
            Chapter(
              id: 'c11_phy_ch1',
              title: 'Vectors & Mathematical Tools',
              lectures: [
                Lecture(
                  title: 'Lecture 1: Vector Addition & Dot Product',
                  videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
                  duration: '22 mins',
                ),
              ],
              notes: [
                Note(
                  title: 'Vector Physics DPP',
                  pdfUrl: 'https://pdfobject.com/pdf/sample.pdf',
                ),
              ],
            ),
          ],
        ),
        Subject(
          name: 'Chemistry',
          chapters: [
            Chapter(
              id: 'c11_chem_ch1',
              title: 'Structure of Atom',
              lectures: [
                Lecture(
                  title: 'Lecture 1: Bohr\'s Model & Quantum Numbers',
                  videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
                  duration: '35 mins',
                ),
              ],
              notes: [
                Note(
                  title: 'Bohr\'s Model Numerical Practice PDF',
                  pdfUrl: 'https://pdfobject.com/pdf/sample.pdf',
                ),
              ],
            ),
          ],
        ),
        Subject(
          name: 'Mathematics',
          chapters: [
            Chapter(
              id: 'c11_math_ch1',
              title: 'Sets & Relations',
              lectures: [
                Lecture(
                  title: 'Lecture 1: Set Operations & Venn Diagrams',
                  videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
                  duration: '15 mins',
                ),
              ],
              notes: [
                Note(
                  title: 'Sets & Relations Formula Sheet',
                  pdfUrl: 'https://pdfobject.com/pdf/sample.pdf',
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ];

  static final List<String> defaultAnnouncements = [
    "🔥 JEE Complete Syllabus Mock Test 1 is live now! Check Mock Tests section.",
    "📢 Chemistry Doubt Class on 'Stoichiometry & Mole Concept' scheduled today at 6:00 PM.",
    "✨ Crest Achievers app launched! Access private, unlimited high-quality streams instantly.",
    "📚 New Physics daily worksheets (DPPs) are added for Class 11th PCM."
  ];
}
