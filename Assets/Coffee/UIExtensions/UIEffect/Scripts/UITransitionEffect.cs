using UnityEngine;
using UnityEngine.UI;

namespace Coffee.UIExtensions
{
	/// <summary>
	/// Transition effect.
	/// </summary>
	public class UITransitionEffect : UIEffectBase
	{
		//################################
		// Constant or Static Members.
		//################################
		public const string shaderName = "UI/Hidden/UI-Effect-Transition";
		static readonly ParameterTexture _ptex = new ParameterTexture(1, 256, "_ParamTex");

		/// <summary>
		/// Effect mode.
		/// </summary>
		public enum EffectMode
		{
			None = 0,
			Mono = 1,
			Cutoff = 2,
		}


		//################################
		// Serialize Members.
		//################################
		[SerializeField] EffectMode m_EffectMode;
		[SerializeField][Range(0, 1)] float m_EffectFactor = 1;


		//################################
		// Public Members.
		//################################
		/// <summary>
		/// Effect factor between 0(no effect) and 1(complete effect).
		/// </summary>
		public float effectFactor
		{
			get { return m_EffectFactor; }
			set
			{
				value = Mathf.Clamp(value, 0, 1);
				if (!Mathf.Approximately(m_EffectFactor, value))
				{
					m_EffectFactor = value;
					SetDirty();
				}
			}
		}

		/// <summary>
		/// Effect mode.
		/// </summary>
		public EffectMode effectMode { get { return m_EffectMode; } }

		/// <summary>
		/// Gets the parameter texture.
		/// </summary>
		public override ParameterTexture ptex { get { return _ptex; } }

		/// <summary>
		/// Modifies the mesh.
		/// </summary>
		public override void ModifyMesh(VertexHelper vh)
		{
			if (!isActiveAndEnabled || m_EffectMode == EffectMode.None)
			{
				return;
			}

			float normalizedIndex = ptex.GetNormalizedIndex(this);
			UIVertex vertex = default(UIVertex);
			int count = vh.currentVertCount;
			for (int i = 0; i < count; i++)
			{
				vh.PopulateUIVertex(ref vertex, i);
				vertex.uv0 = new Vector2(
					Packer.ToFloat(vertex.uv0.x, vertex.uv0.y),
					normalizedIndex
				);
				vh.SetUIVertex(vertex, i);
			}
		}

		protected override void SetDirty()
		{
			ptex.RegisterMaterial(targetGraphic.material);
			ptex.SetData(this, 0, m_EffectFactor);	// param1.x : effect factor
		}

#if UNITY_EDITOR
		/// <summary>
		/// Gets the material.
		/// </summary>
		/// <returns>The material.</returns>
		protected override Material GetMaterial()
		{
			return m_EffectMode != EffectMode.None
				? MaterialResolver.GetOrGenerateMaterialVariant(Shader.Find(shaderName), m_EffectMode)
				: null;
		}
#endif
	}
}
