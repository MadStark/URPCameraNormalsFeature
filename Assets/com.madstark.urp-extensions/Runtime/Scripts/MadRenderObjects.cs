using UnityEngine;
using UnityEngine.Rendering.Universal;

public class MadRenderObjects : ScriptableRendererFeature
{
    [System.Serializable]
    public class Settings
    {
        public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingOpaques;

        public Material overrideMaterial;
        public int overrideMaterialPassIndex;

        public FilterSettings filterSettings = new FilterSettings();

        public TargetSettings targetSettings = new TargetSettings();
    }

    [System.Serializable]
    public class FilterSettings
    {
        public RenderQueueType renderQueue = RenderQueueType.Opaque;
        public LayerMask layerMask = 0;
    }

    [System.Serializable]
    public class TargetSettings
    {
        public RenderTargetType renderTargetType = RenderTargetType.CameraTarget;
        public string targetTextureName = "_MadCustomTextureOutput";
    }

    public enum RenderQueueType
    {
        Opaque,
        Transparent
    }

    public enum RenderTargetType
    {
        CameraTarget,
        Texture
    }


    public Settings settings = new Settings();

    private MadRenderObjectsPass pass;
    private RenderTargetHandle renderTextureHandle;


    public override void Create()
    {
        pass = new MadRenderObjectsPass(name, settings.filterSettings.layerMask, settings.filterSettings.renderQueue)
        {
            renderPassEvent = settings.renderPassEvent
        };

        pass.overrideMaterial = settings.overrideMaterial;
        pass.overrideMaterialPassIndex = settings.overrideMaterialPassIndex;

        renderTextureHandle.Init(settings.targetSettings.targetTextureName);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        pass.Setup(settings.targetSettings.renderTargetType == RenderTargetType.CameraTarget
                   ? RenderTargetHandle.CameraTarget
                   : renderTextureHandle);
        renderer.EnqueuePass(pass);
    }
}
